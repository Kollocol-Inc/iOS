//
//  APIClientTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct APIClientTests {
    @Test
    func requestDecodesSuccessfulJSONResponse() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: #"{"value":"ok"}"#)

        let response = try await context.makeAPIClient().request(ValueEndpoint())

        #expect(response.value == "ok")
        #expect(context.recordedRequests().count == 1)
    }

    @Test
    func requestBuildsMethodHeadersQueryAndJSONBody() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: #"{"value":"accepted"}"#)

        let response = try await context.makeAPIClient().request(
            ValueEndpoint(
                method: .post,
                path: "/resource",
                query: [URLQueryItem(name: "page", value: "2")],
                headers: ["X-Custom": "custom-header"],
                bodyValue: "payload"
            )
        )

        #expect(response.value == "accepted")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "X-Custom") == "custom-header")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.url?.path == "/resource")
        #expect(request.url?.query == "page=2")

        let bodyData = try #require(extractBodyData(from: request))
        let bodyObject = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(bodyObject["value"] == "payload")
    }

    @Test
    func requestReturnsEmptyResponseForEmptyBody() async throws {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 204, data: Data())

        _ = try await context.makeAPIClient().request(EmptyEndpoint())

        #expect(context.recordedRequests().count == 1)
    }

    @Test
    func requestThrowsHTTPStatusForNonSuccessCodes() async {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 500, data: Data("server-failed".utf8))

        do {
            _ = try await context.makeAPIClient().request(ValueEndpoint())
            Issue.record("Expected NetworkError.httpStatus")
        } catch let error as NetworkError {
            guard case .httpStatus(let code, let data) = error else {
                Issue.record("Expected NetworkError.httpStatus, got \(error)")
                return
            }
            #expect(code == 500)
            #expect(String(data: data, encoding: .utf8) == "server-failed")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestThrowsDecodingErrorWhenBodyDoesNotMatchResponse() async {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: #"{"unexpected":"value"}"#)

        do {
            _ = try await context.makeAPIClient().request(ValueEndpoint())
            Issue.record("Expected NetworkError.decoding")
        } catch let error as NetworkError {
            guard case .decoding = error else {
                Issue.record("Expected NetworkError.decoding, got \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestWrapsURLErrorAsTransportError() async {
        let context = makeNetworkTestContext()
        context.enqueue(error: URLError(.notConnectedToInternet))

        do {
            _ = try await context.makeAPIClient().request(ValueEndpoint())
            Issue.record("Expected NetworkError.transport")
        } catch let error as NetworkError {
            guard case .transport(let urlError) = error else {
                Issue.record("Expected NetworkError.transport, got \(error)")
                return
            }
            #expect(urlError.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func requestRetriesAfterUnauthorizedWhenInterceptorAllowsIt() async throws {
        let context = makeNetworkTestContext()
        let interceptor = APIClientInterceptorSpy()
        await interceptor.setRetryDecision(attempt: 0, value: true)

        context.enqueueJSON(statusCode: 401, json: #"{"error":"unauthorized"}"#)
        context.enqueueJSON(statusCode: 200, json: #"{"value":"retried"}"#)

        let response = try await context.makeAPIClient(interceptor: interceptor).request(ValueEndpoint())

        #expect(response.value == "retried")
        #expect(await interceptor.adaptCallsCount() == 2)
        #expect(await interceptor.shouldRetryCalls() == [.init(statusCode: 401, attempt: 0)])
        #expect(await interceptor.forcedLogoutCallsCount() == 0)
        #expect(context.recordedRequests().count == 2)
    }

    @Test
    func requestForcesLogoutWhenRetriedRequestIsStillUnauthorized() async {
        let context = makeNetworkTestContext()
        let interceptor = APIClientInterceptorSpy()
        await interceptor.setRetryDecision(attempt: 0, value: true)

        context.enqueueJSON(statusCode: 401, json: #"{"error":"unauthorized"}"#)
        context.enqueueJSON(statusCode: 401, json: #"{"error":"still unauthorized"}"#)

        do {
            _ = try await context.makeAPIClient(interceptor: interceptor).request(ValueEndpoint())
            Issue.record("Expected NetworkError.httpStatus")
        } catch let error as NetworkError {
            guard case .httpStatus(let code, _) = error else {
                Issue.record("Expected NetworkError.httpStatus, got \(error)")
                return
            }
            #expect(code == 401)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(await interceptor.adaptCallsCount() == 2)
        #expect(
            await interceptor.shouldRetryCalls() == [
                .init(statusCode: 401, attempt: 0),
                .init(statusCode: 401, attempt: 1)
            ]
        )
        #expect(await interceptor.forcedLogoutCallsCount() == 1)
    }

    @Test
    func requestDoesNotForceLogoutWhenUnauthorizedWithoutRetry() async {
        let context = makeNetworkTestContext()
        let interceptor = APIClientInterceptorSpy()
        context.enqueueJSON(statusCode: 401, json: #"{"error":"unauthorized"}"#)

        do {
            _ = try await context.makeAPIClient(interceptor: interceptor).request(ValueEndpoint())
            Issue.record("Expected NetworkError.httpStatus")
        } catch let error as NetworkError {
            guard case .httpStatus(let code, _) = error else {
                Issue.record("Expected NetworkError.httpStatus, got \(error)")
                return
            }
            #expect(code == 401)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(await interceptor.adaptCallsCount() == 1)
        #expect(await interceptor.shouldRetryCalls() == [.init(statusCode: 401, attempt: 0)])
        #expect(await interceptor.forcedLogoutCallsCount() == 0)
    }
}

private struct ValueEndpoint: Endpoint {
    typealias Response = ValueResponse

    var method: HTTPMethod = .get
    var path: String = "/value"
    var query: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var bodyValue: String? = nil

    var body: AnyEncodable? {
        guard let bodyValue else { return nil }
        return AnyEncodable(Body(value: bodyValue))
    }

    private struct Body: Encodable {
        let value: String
    }
}

private struct EmptyEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var method: HTTPMethod { .get }
    var path: String { "/empty" }
}

private struct ValueResponse: Decodable {
    let value: String
}

private struct RetryCall: Equatable {
    let statusCode: Int
    let attempt: Int
}

private actor APIClientInterceptorSpy: RequestInterceptor {
    private var adaptedRequests: [URLRequest] = []
    private var shouldRetryCallsStorage: [RetryCall] = []
    private var retryDecisionsByAttempt: [Int: Bool] = [:]
    private var forcedLogoutCalls = 0

    func setRetryDecision(attempt: Int, value: Bool) {
        retryDecisionsByAttempt[attempt] = value
    }

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        adaptedRequests.append(request)
        var adaptedRequest = request
        adaptedRequest.setValue("yes", forHTTPHeaderField: "X-Adapted")
        return adaptedRequest
    }

    func shouldRetry(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        attempt: Int
    ) async -> Bool {
        shouldRetryCallsStorage.append(.init(statusCode: response.statusCode, attempt: attempt))
        return retryDecisionsByAttempt[attempt] ?? false
    }

    func forcedLogout() async {
        forcedLogoutCalls += 1
    }

    func adaptCallsCount() -> Int {
        adaptedRequests.count
    }

    func shouldRetryCalls() -> [RetryCall] {
        shouldRetryCallsStorage
    }

    func forcedLogoutCallsCount() -> Int {
        forcedLogoutCalls
    }
}

private func extractBodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody {
        return body
    }

    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    let bufferSize = 1_024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    var data = Data()
    while stream.hasBytesAvailable {
        let count = stream.read(buffer, maxLength: bufferSize)
        if count < 0 {
            return nil
        }
        if count == 0 {
            break
        }
        data.append(buffer, count: count)
    }

    return data
}
