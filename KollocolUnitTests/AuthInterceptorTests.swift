//
//  AuthInterceptorTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

@MainActor
struct AuthInterceptorTests {
    @Test
    func adaptAddsAuthorizationHeaderForNonRefreshPath() async throws {
        let context = await makeAuthInterceptorContext(accessToken: "access-1")
        let request = URLRequest(url: URL(string: "https://example.com/users/me")!)

        let adaptedRequest = try await context.interceptor.adapt(request)

        #expect(adaptedRequest.value(forHTTPHeaderField: "Authorization") == "Bearer access-1")
    }

    @Test
    func adaptSkipsAuthorizationForRefreshPath() async throws {
        let context = await makeAuthInterceptorContext(accessToken: "access-2")
        let request = URLRequest(url: URL(string: "https://example.com/auth/refresh")!)

        let adaptedRequest = try await context.interceptor.adapt(request)

        #expect(adaptedRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func adaptWithoutTokenLeavesAuthorizationEmpty() async throws {
        let context = await makeAuthInterceptorContext()
        let request = URLRequest(url: URL(string: "https://example.com/users/me")!)

        let adaptedRequest = try await context.interceptor.adapt(request)

        #expect(adaptedRequest.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test
    func shouldRetryReturnsTrueWhenRefreshSucceeds() async {
        let context = await makeAuthInterceptorContext(refreshToken: "refresh-1")
        await context.refresher.enqueueSuccess(
            TokenPair(accessToken: "new-access", refreshToken: "new-refresh")
        )

        let shouldRetry = await context.interceptor.shouldRetry(
            request: makeRequest(path: "/users/me"),
            response: makeResponse(statusCode: 401, path: "/users/me"),
            data: Data(),
            attempt: 0
        )

        #expect(shouldRetry)
        #expect(await context.refresher.callsCount() == 1)
        let storedPair = await context.store.lastSetPair()
        #expect(storedPair?.accessToken == "new-access")
        #expect(storedPair?.refreshToken == "new-refresh")
        #expect(context.logoutProbe.calls == 0)
    }

    @Test
    func shouldRetryReturnsFalseAndForcesLogoutWhenRefreshFails() async {
        let context = await makeAuthInterceptorContext(refreshToken: "refresh-2")
        await context.refresher.enqueueFailure(.unauthorized)

        let shouldRetry = await context.interceptor.shouldRetry(
            request: makeRequest(path: "/users/me"),
            response: makeResponse(statusCode: 401, path: "/users/me"),
            data: Data(),
            attempt: 0
        )

        #expect(shouldRetry == false)
        #expect(await context.refresher.callsCount() == 1)
        #expect(await context.store.clearCallsCount() == 1)
        #expect(context.logoutProbe.calls == 1)
    }

    @Test
    func shouldRetryReturnsFalseForRepeatedAttempt() async {
        let context = await makeAuthInterceptorContext(refreshToken: "refresh-3")

        let shouldRetry = await context.interceptor.shouldRetry(
            request: makeRequest(path: "/users/me"),
            response: makeResponse(statusCode: 401, path: "/users/me"),
            data: Data(),
            attempt: 1
        )

        #expect(shouldRetry == false)
        #expect(await context.refresher.callsCount() == 0)
        #expect(context.logoutProbe.calls == 0)
    }

    @Test
    func shouldRetryReturnsFalseForNonAuthorizationStatuses() async {
        let context = await makeAuthInterceptorContext(refreshToken: "refresh-4")

        let shouldRetry = await context.interceptor.shouldRetry(
            request: makeRequest(path: "/users/me"),
            response: makeResponse(statusCode: 500, path: "/users/me"),
            data: Data(),
            attempt: 0
        )

        #expect(shouldRetry == false)
        #expect(await context.refresher.callsCount() == 0)
        #expect(context.logoutProbe.calls == 0)
    }

    @Test
    func forcedLogoutDelegatesToSessionManager() async {
        let context = await makeAuthInterceptorContext(refreshToken: "refresh-5")

        await context.interceptor.forcedLogout()

        #expect(await context.store.clearCallsCount() == 1)
        #expect(context.logoutProbe.calls == 1)
    }
}

private actor AuthInterceptorTokenStoreMock: TokenStoring {
    private var accessTokenStorage: String?
    private var refreshTokenStorage: String?
    private var lastSetPairStorage: TokenPair?
    private var clearCalls = 0

    func setAccessToken(_ token: String?) {
        accessTokenStorage = token
    }

    func setRefreshToken(_ token: String?) {
        refreshTokenStorage = token
    }

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

private actor AuthInterceptorRefresherMock: TokenRefreshing {
    private enum Result {
        case success(TokenPair)
        case failure(AuthServiceError)
    }

    private var resultsQueue: [Result] = []
    private var calls = 0

    func enqueueSuccess(_ pair: TokenPair) {
        resultsQueue.append(.success(pair))
    }

    func enqueueFailure(_ error: AuthServiceError) {
        resultsQueue.append(.failure(error))
    }

    func callsCount() -> Int {
        calls
    }

    func refresh(using refreshToken: String) async throws -> TokenPair {
        calls += 1

        guard resultsQueue.isEmpty == false else {
            return TokenPair(accessToken: "default-access", refreshToken: "default-refresh")
        }

        switch resultsQueue.removeFirst() {
        case .success(let pair):
            return pair
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class AuthInterceptorLogoutProbe {
    private(set) var calls = 0

    func mark() {
        calls += 1
    }
}

@MainActor
private func makeAuthInterceptorContext(
    accessToken: String? = nil,
    refreshToken: String? = nil
) async -> (
    interceptor: AuthInterceptor,
    store: AuthInterceptorTokenStoreMock,
    refresher: AuthInterceptorRefresherMock,
    logoutProbe: AuthInterceptorLogoutProbe
) {
    let store = AuthInterceptorTokenStoreMock()
    let refresher = AuthInterceptorRefresherMock()
    let logoutProbe = AuthInterceptorLogoutProbe()

    await store.setAccessToken(accessToken)
    await store.setRefreshToken(refreshToken)

    let session = SessionManager(
        store: store,
        refresher: refresher,
        onForcedLogout: {
            logoutProbe.mark()
        }
    )

    let interceptor = AuthInterceptor(session: session, refreshPath: "/auth/refresh")
    return (interceptor, store, refresher, logoutProbe)
}

private func makeRequest(path: String) -> URLRequest {
    URLRequest(url: URL(string: "https://example.com\(path)")!)
}

private func makeResponse(statusCode: Int, path: String) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://example.com\(path)")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: [:]
    )!
}
