//
//  APIClient.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

final class APIClient {
    private enum Constants {
        static let jsonContentType = "application/json"
    }

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let interceptor: RequestInterceptor?
    private let logger: (@Sendable (String) -> Void)?

    init(
        baseURL: URL,
        session: URLSession,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        interceptor: RequestInterceptor? = nil,
        logger: (@Sendable (String) -> Void)? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.interceptor = interceptor
        #if DEBUG
        self.logger = logger ?? { Swift.print($0) }
        #else
        self.logger = logger
        #endif
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint, attempt: 0)
    }

    private func request<E: Endpoint>(_ endpoint: E, attempt: Int) async throws -> E.Response {
        let requestId = UUID().uuidString
        let startedAt = CFAbsoluteTimeGetCurrent()

        var req = try makeRequest(endpoint)
        if let interceptor {
            req = try await interceptor.adapt(req)
        }

        logRequest(req, requestId: requestId, attempt: attempt)

        do {
            let (data, response) = try await perform(req)
            let duration = CFAbsoluteTimeGetCurrent() - startedAt

            logResponse(response, data: data, requestId: requestId, attempt: attempt, duration: duration)

            let status = response.statusCode

            if status == 401 || status == 403 {
                if let interceptor, await interceptor.shouldRetry(request: req, response: response, data: data, attempt: attempt) {
                    logLine("◀️ retry requestId=\(requestId) attempt=\(attempt + 1)")
                    return try await request(endpoint, attempt: attempt + 1)
                }
                if attempt > 0 {
                    await interceptor?.forcedLogout()
                }
                throw NetworkError.httpStatus(code: status, data: data)
            }

            guard (200...299).contains(status) else {
                throw NetworkError.httpStatus(code: status, data: data)
            }

            do {
                return try decoder.decode(E.Response.self, from: data)
            } catch {
                throw NetworkError.decoding(error)
            }
        } catch {
            let duration = CFAbsoluteTimeGetCurrent() - startedAt
            logError(error, requestId: requestId, attempt: attempt, duration: duration)
            throw error
        }
    }

    private func makeRequest<E: Endpoint>(_ endpoint: E) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }

        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let multipart = endpoint.multipart {
            request.setValue(multipart.contentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
            request.httpBody = multipart.encode()
            return request
        }

        if let body = endpoint.body {
            request.setValue(Constants.jsonContentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request, delegate: nil)
            guard let http = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            return (data, http)
        } catch let e as URLError {
            throw NetworkError.transport(e)
        }
    }

    private func logRequest(_ request: URLRequest, requestId: String, attempt: Int) {
        guard logger != nil else { return }

        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        let headers = redactHeaders(request.allHTTPHeaderFields ?? [:])

        let body = previewBodyForLogging(request)

        logLine("▶️ requestId=\(requestId) attempt=\(attempt) \(method) \(url)")
        if !headers.isEmpty {
            logLine("headers=\(headers)")
        }
        if let body, !body.isEmpty {
            logLine("body=\(body)")
        }
    }

    private func previewBodyForLogging(_ request: URLRequest) -> String? {
        guard let data = request.httpBody, !data.isEmpty else { return nil }

        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        if contentType.contains("multipart/form-data") {
            return "multipart bytes=\(data.count)"
        }

        return previewBody(data)
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, requestId: String, attempt: Int, duration: CFTimeInterval) {
        guard logger != nil else { return }

        let headers = redactHeaders(response.allHeaderFields.reduce(into: [String: String]()) { dict, pair in
            if let key = pair.key as? String {
                dict[key] = "\(pair.value)"
            }
        })
        let body = previewBody(data)

        logLine("✅ requestId=\(requestId) attempt=\(attempt) status=\(response.statusCode) time=\(String(format: "%.3f", duration))s")
        if !headers.isEmpty {
            logLine("responseHeaders=\(headers)")
        }
        if let body, !body.isEmpty {
            logLine("responseBody=\(body)")
        }
    }

    private func logError(_ error: Error, requestId: String, attempt: Int, duration: CFTimeInterval) {
        guard logger != nil else { return }

        if let e = error as? NetworkError {
            switch e {
            case .httpStatus(let code, let data):
                let body = previewBody(data)
                logLine("❌ requestId=\(requestId) attempt=\(attempt) status=\(code) time=\(String(format: "%.3f", duration))s error=\(String(describing: e))")
                if let body, !body.isEmpty {
                    logLine("responseBody=\(body)")
                }
                return
            default:
                break
            }
        }

        logLine("❌ requestId=\(requestId) attempt=\(attempt) time=\(String(format: "%.3f", duration))s error=\(String(describing: error))")
    }

    private func logLine(_ text: String) {
        logger?(text)
    }

    private func redactHeaders(_ headers: [String: String]) -> [String: String] {
        var result = headers
        let keysToRedact = ["Authorization", "Cookie", "Set-Cookie"]
        for key in keysToRedact {
            if result[key] != nil {
                result[key] = "REDACTED"
            }
        }
        return result
    }

    private func previewBody(_ data: Data?, limit: Int = 2000) -> String? {
        guard let data, !data.isEmpty else { return nil }

        if let json = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]),
           var text = String(data: pretty, encoding: .utf8) {
            if text.count > limit {
                text = String(text.prefix(limit)) + "…"
            }
            return text
        }

        if var text = String(data: data, encoding: .utf8) {
            if text.count > limit {
                text = String(text.prefix(limit)) + "…"
            }
            return text
        }

        return "bytes=\(data.count)"
    }
}
