//
//  APIClient.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let interceptor: RequestInterceptor?

    init(
        baseURL: URL,
        session: URLSession,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        interceptor: RequestInterceptor? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.interceptor = interceptor
    }

    func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint, attempt: 0)
    }

    private func request<E: Endpoint>(_ endpoint: E, attempt: Int) async throws -> E.Response {
        var req = try makeRequest(endpoint)
        if let interceptor {
            req = try await interceptor.adapt(req)
        }

        let (data, response) = try await perform(req)
        let status = response.statusCode

        if status == 401 || status == 403 {
            if let interceptor, await interceptor.shouldRetry(request: req, response: response, data: data, attempt: attempt) {
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

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
}
