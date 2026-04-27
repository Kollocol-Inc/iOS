//
//  NetworkingTestSupport.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
@testable import Kollocol

struct NetworkTestContext {
    let host: String
    let baseURL: URL
    let session: URLSession

    func makeAPIClient(interceptor: RequestInterceptor? = nil) -> APIClient {
        APIClient(
            baseURL: baseURL,
            session: session,
            interceptor: interceptor,
            logger: { _ in }
        )
    }

    func reset() {
        TestURLProtocolStub.reset(host: host)
    }

    func enqueue(statusCode: Int, data: Data, headers: [String: String] = [:]) {
        TestURLProtocolStub.enqueue(
            host: host,
            result: .success(statusCode: statusCode, data: data, headers: headers)
        )
    }

    func enqueueJSON(statusCode: Int, json: String, headers: [String: String] = [:]) {
        var normalizedHeaders = headers
        if normalizedHeaders["Content-Type"] == nil {
            normalizedHeaders["Content-Type"] = "application/json"
        }

        enqueue(
            statusCode: statusCode,
            data: Data(json.utf8),
            headers: normalizedHeaders
        )
    }

    func enqueue(error: Error) {
        TestURLProtocolStub.enqueue(host: host, result: .failure(error))
    }

    func recordedRequests() -> [URLRequest] {
        TestURLProtocolStub.recordedRequests(host: host)
    }
}

func makeNetworkTestContext() -> NetworkTestContext {
    let host = "test-\(UUID().uuidString.lowercased()).example.com"
    let baseURL = URL(string: "https://\(host)")!

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [TestURLProtocolStub.self]
    let session = URLSession(configuration: configuration)

    return NetworkTestContext(
        host: host,
        baseURL: baseURL,
        session: session
    )
}

private final class TestURLProtocolStub: URLProtocol {
    enum StubbedResult {
        case success(statusCode: Int, data: Data, headers: [String: String])
        case failure(Error)
    }

    private static let lock = NSLock()
    private static var stubsByHost: [String: [StubbedResult]] = [:]
    private static var requestsByHost: [String: [URLRequest]] = [:]

    static func reset(host: String) {
        lock.lock()
        defer { lock.unlock() }

        stubsByHost[host] = []
        requestsByHost[host] = []
    }

    static func enqueue(host: String, result: StubbedResult) {
        lock.lock()
        defer { lock.unlock() }

        stubsByHost[host, default: []].append(result)
    }

    static func recordedRequests(host: String) -> [URLRequest] {
        lock.lock()
        defer { lock.unlock() }

        return requestsByHost[host, default: []]
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let host = request.url?.host ?? "default"

        Self.lock.lock()
        Self.requestsByHost[host, default: []].append(request)
        let result = Self.stubsByHost[host, default: []].isEmpty
            ? nil
            : Self.stubsByHost[host, default: []].removeFirst()
        Self.lock.unlock()

        guard let result else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        switch result {
        case .success(let statusCode, let data, let headers):
            let responseURL = request.url ?? URL(string: "https://\(host)")!
            let response = HTTPURLResponse(
                url: responseURL,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)

        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
    }
}
