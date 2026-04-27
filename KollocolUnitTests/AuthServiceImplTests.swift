//
//  AuthServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct AuthServiceImplTests {
    @Test
    func loginSuccessSendsLoginRequest() async throws {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 200, data: Data())

        let tokenStore = AuthServiceTokenStoreMock()
        let udService = AuthServiceUserDefaultsMock()
        let service = AuthServiceImpl(
            api: context.makeAPIClient(),
            tokenStore: tokenStore,
            udService: udService
        )

        try await service.login(using: "user@example.com")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/login")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["email"] == "user@example.com")
    }

    @Test
    func loginMaps429ToTooManyRequests() async {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 429, json: #"{"error":"rate_limited"}"#)

        let service = AuthServiceImpl(
            api: context.makeAPIClient(),
            tokenStore: AuthServiceTokenStoreMock(),
            udService: AuthServiceUserDefaultsMock()
        )

        do {
            try await service.login(using: "user@example.com")
            Issue.record("Expected AuthServiceError.tooManyRequests")
        } catch let error as AuthServiceError {
            #expect(isAuthServiceError(error, .tooManyRequests))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func resendCodeUsesLoginEndpoint() async throws {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 200, data: Data())

        let service = AuthServiceImpl(
            api: context.makeAPIClient(),
            tokenStore: AuthServiceTokenStoreMock(),
            udService: AuthServiceUserDefaultsMock()
        )

        try await service.resendCode(to: "resend@example.com")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/login")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["email"] == "resend@example.com")
    }

    @Test
    func verifySuccessStoresTokensAndUpdatesRegistrationFlag() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "access_token": "access-1",
              "refresh_token": "refresh-1",
              "is_registered": true,
              "user_id": "user-1"
            }
            """#
        )

        let tokenStore = AuthServiceTokenStoreMock()
        let udService = AuthServiceUserDefaultsMock()
        let service = AuthServiceImpl(
            api: context.makeAPIClient(),
            tokenStore: tokenStore,
            udService: udService
        )

        let isRegistered = try await service.verify(code: "1234", with: "verify@example.com")

        #expect(isRegistered)
        #expect(udService.isRegistered)

        let storedPair = await tokenStore.lastSetPair()
        #expect(storedPair?.accessToken == "access-1")
        #expect(storedPair?.refreshToken == "refresh-1")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/auth/verify")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["code"] == "1234")
        #expect(body["email"] == "verify@example.com")
    }

    @Test
    func verifyMapsOfflineTransportError() async {
        let context = makeNetworkTestContext()
        context.enqueue(error: URLError(.notConnectedToInternet))

        let service = AuthServiceImpl(
            api: context.makeAPIClient(),
            tokenStore: AuthServiceTokenStoreMock(),
            udService: AuthServiceUserDefaultsMock()
        )

        do {
            _ = try await service.verify(code: "0000", with: "offline@example.com")
            Issue.record("Expected AuthServiceError.offline")
        } catch let error as AuthServiceError {
            #expect(isAuthServiceError(error, .offline))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func logoutClearsTokenStore() async throws {
        let tokenStore = AuthServiceTokenStoreMock()
        let service = AuthServiceImpl(
            api: makeNetworkTestContext().makeAPIClient(),
            tokenStore: tokenStore,
            udService: AuthServiceUserDefaultsMock()
        )

        try await service.logout()

        #expect(await tokenStore.clearCallsCount() == 1)
    }
}

private actor AuthServiceTokenStoreMock: TokenStoring {
    private var accessTokenStorage: String?
    private var refreshTokenStorage: String?
    private var lastSetPairStorage: TokenPair?
    private var clearCalls = 0

    func accessToken() async -> String? {
        accessTokenStorage
    }

    func refreshToken() async -> String? {
        refreshTokenStorage
    }

    func set(_ pair: TokenPair) async {
        lastSetPairStorage = pair
        accessTokenStorage = pair.accessToken
        refreshTokenStorage = pair.refreshToken
    }

    func clear() async {
        clearCalls += 1
        accessTokenStorage = nil
        refreshTokenStorage = nil
    }

    func clearCallsCount() -> Int {
        clearCalls
    }

    func lastSetPair() -> TokenPair? {
        lastSetPairStorage
    }
}

private final class AuthServiceUserDefaultsMock: UserDefaultsService {
    var isRegistered = false
    var appThemePreference: AppThemePreference = .system
    var appLanguagePreference: AppLanguagePreference = .system

    private var storage: [UserDefaultsKey: Any] = [:]

    func set<T>(_ value: T?, for key: UserDefaultsKey) {
        storage[key] = value
    }

    func value<T>(for key: UserDefaultsKey) -> T? {
        storage[key] as? T
    }

    func remove(_ key: UserDefaultsKey) {
        storage[key] = nil
    }

    func exists(_ key: UserDefaultsKey) -> Bool {
        storage[key] != nil
    }
}

private func isAuthServiceError(_ actual: AuthServiceError, _ expected: AuthServiceError) -> Bool {
    switch (actual, expected) {
    case (.badRequest, .badRequest),
            (.tooManyRequests, .tooManyRequests),
            (.unauthorized, .unauthorized),
            (.offline, .offline),
            (.server, .server),
            (.unknown, .unknown):
        return true
    default:
        return false
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
