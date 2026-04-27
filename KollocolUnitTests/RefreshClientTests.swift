//
//  RefreshClientTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct RefreshClientTests {
    @Test
    func refreshSuccessReturnsTokenPairAndUsesRefreshEndpoint() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "access_token": "new-access",
              "refresh_token": "new-refresh",
              "message": "ok",
              "success": true
            }
            """#
        )

        let client = RefreshClient(api: context.makeAPIClient())

        let pair = try await client.refresh(using: "refresh-123")

        #expect(pair.accessToken == "new-access")
        #expect(pair.refreshToken == "new-refresh")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/refresh")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["refresh_token"] == "refresh-123")
    }

    @Test
    func refreshPropagatesNetworkError() async {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 401, data: Data("unauthorized".utf8))

        let client = RefreshClient(api: context.makeAPIClient())

        do {
            _ = try await client.refresh(using: "invalid-token")
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
