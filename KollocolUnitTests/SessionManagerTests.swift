//
//  SessionManagerTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

@MainActor
struct SessionManagerTests {
    @Test
    func accessTokenReturnsValueFromStore() async {
        let store = SessionManagerTokenStoreMock()
        await store.setAccessToken("access-1")
        let manager = makeSessionManager(store: store, refresher: SessionManagerRefresherMock())

        let token = await manager.manager.accessToken()

        #expect(token == "access-1")
    }

    @Test
    func refreshTokensWithoutRefreshTokenThrowsUnauthorized() async {
        let store = SessionManagerTokenStoreMock()
        let refresher = SessionManagerRefresherMock()
        let manager = makeSessionManager(store: store, refresher: refresher)

        do {
            _ = try await manager.manager.refreshTokens()
            Issue.record("Expected AuthServiceError.unauthorized")
        } catch let error as AuthServiceError {
            #expect(isAuthServiceError(error, .unauthorized))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        #expect(await refresher.callsCount() == 0)
    }

    @Test
    func refreshTokensSuccessStoresAndReturnsPair() async throws {
        let store = SessionManagerTokenStoreMock()
        await store.setRefreshToken("refresh-1")
        let refresher = SessionManagerRefresherMock()
        await refresher.enqueueSuccess(TokenPair(accessToken: "new-access", refreshToken: "new-refresh"))
        let manager = makeSessionManager(store: store, refresher: refresher)

        let pair = try await manager.manager.refreshTokens()

        #expect(pair.accessToken == "new-access")
        #expect(pair.refreshToken == "new-refresh")
        #expect(await refresher.callsCount() == 1)

        let storedPair = await store.lastSetPair()
        #expect(storedPair?.accessToken == "new-access")
        #expect(storedPair?.refreshToken == "new-refresh")
    }

    @Test
    func refreshTokensDeduplicatesConcurrentRequests() async throws {
        let store = SessionManagerTokenStoreMock()
        await store.setRefreshToken("refresh-2")
        let refresher = SessionManagerRefresherMock()
        await refresher.setDelayNanoseconds(100_000_000)
        await refresher.enqueueSuccess(TokenPair(accessToken: "access-2", refreshToken: "refresh-2-new"))
        let manager = makeSessionManager(store: store, refresher: refresher)

        async let firstCall = manager.manager.refreshTokens()
        async let secondCall = manager.manager.refreshTokens()

        let firstPair = try await firstCall
        let secondPair = try await secondCall

        #expect(firstPair.accessToken == "access-2")
        #expect(secondPair.accessToken == "access-2")
        #expect(await refresher.callsCount() == 1)
        #expect(await store.setCallsCount() == 1)
    }

    @Test
    func forcedLogoutClearsStoreAndCallsCallback() async {
        let store = SessionManagerTokenStoreMock()
        let manager = makeSessionManager(store: store, refresher: SessionManagerRefresherMock())

        await manager.manager.forcedLogout()

        #expect(await store.clearCallsCount() == 1)
        #expect(await manager.logoutProbe.callsCount() == 1)
    }
}

private actor SessionManagerTokenStoreMock: TokenStoring {
    private var accessTokenStorage: String?
    private var refreshTokenStorage: String?
    private var lastSetPairStorage: TokenPair?
    private var setCalls = 0
    private var clearCalls = 0

    func setAccessToken(_ token: String?) {
        accessTokenStorage = token
    }

    func setRefreshToken(_ token: String?) {
        refreshTokenStorage = token
    }

    func lastSetPair() -> TokenPair? {
        lastSetPairStorage
    }

    func setCallsCount() -> Int {
        setCalls
    }

    func clearCallsCount() -> Int {
        clearCalls
    }

    func accessToken() async -> String? {
        accessTokenStorage
    }

    func refreshToken() async -> String? {
        refreshTokenStorage
    }

    func set(_ pair: TokenPair) async {
        setCalls += 1
        lastSetPairStorage = pair
        accessTokenStorage = pair.accessToken
        refreshTokenStorage = pair.refreshToken
    }

    func clear() async {
        clearCalls += 1
        accessTokenStorage = nil
        refreshTokenStorage = nil
    }
}

private actor SessionManagerRefresherMock: TokenRefreshing {
    private enum Result {
        case success(TokenPair)
        case failure(AuthServiceError)
    }

    private var resultsQueue: [Result] = []
    private var calls = 0
    private var delayNanoseconds: UInt64 = 0

    func enqueueSuccess(_ pair: TokenPair) {
        resultsQueue.append(.success(pair))
    }

    func enqueueFailure(_ error: AuthServiceError) {
        resultsQueue.append(.failure(error))
    }

    func setDelayNanoseconds(_ delay: UInt64) {
        delayNanoseconds = delay
    }

    func callsCount() -> Int {
        calls
    }

    func refresh(using refreshToken: String) async throws -> TokenPair {
        calls += 1

        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
        }

        guard resultsQueue.isEmpty == false else {
            return TokenPair(accessToken: "default-access", refreshToken: "default-refresh")
        }

        let result = resultsQueue.removeFirst()
        switch result {
        case .success(let pair):
            return pair
        case .failure(let error):
            throw error
        }
    }
}

@MainActor
private final class SessionManagerLogoutProbe {
    private(set) var calls = 0

    func mark() {
        calls += 1
    }
}

private actor SessionManagerLogoutProbeAccessor {
    private let probe: SessionManagerLogoutProbe

    init(probe: SessionManagerLogoutProbe) {
        self.probe = probe
    }

    func callsCount() async -> Int {
        await MainActor.run {
            probe.calls
        }
    }
}

@MainActor
private func makeSessionManager(
    store: SessionManagerTokenStoreMock,
    refresher: SessionManagerRefresherMock
) -> (
    manager: SessionManager,
    logoutProbe: SessionManagerLogoutProbeAccessor
) {
    let probe = SessionManagerLogoutProbe()
    let probeAccessor = SessionManagerLogoutProbeAccessor(probe: probe)

    let manager = SessionManager(
        store: store,
        refresher: refresher,
        onForcedLogout: {
            probe.mark()
        }
    )

    return (manager, probeAccessor)
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
