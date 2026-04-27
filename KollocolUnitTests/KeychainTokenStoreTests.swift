//
//  KeychainTokenStoreTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct KeychainTokenStoreTests {
    @Test
    func emptyStoreReturnsNilTokens() async {
        let serviceName = makeUniqueTokenStoreService()
        let store = KeychainTokenStore(service: serviceName)
        await store.clear()

        #expect(await store.accessToken() == nil)
        #expect(await store.refreshToken() == nil)
    }

    @Test
    func setPersistsTokensAndCanBeReadByAnotherStoreInstance() async {
        let serviceName = makeUniqueTokenStoreService()
        let firstStore = KeychainTokenStore(service: serviceName)
        let secondStore = KeychainTokenStore(service: serviceName)

        await firstStore.clear()
        await firstStore.set(TokenPair(accessToken: "access-1", refreshToken: "refresh-1"))

        #expect(await firstStore.accessToken() == "access-1")
        #expect(await firstStore.refreshToken() == "refresh-1")
        #expect(await secondStore.accessToken() == "access-1")
        #expect(await secondStore.refreshToken() == "refresh-1")
    }

    @Test
    func clearRemovesStoredTokens() async {
        let serviceName = makeUniqueTokenStoreService()
        let store = KeychainTokenStore(service: serviceName)

        await store.set(TokenPair(accessToken: "access-2", refreshToken: "refresh-2"))
        await store.clear()

        #expect(await store.accessToken() == nil)
        #expect(await store.refreshToken() == nil)
    }
}

private func makeUniqueTokenStoreService() -> String {
    "com.kollocol.tests.token-store.\(UUID().uuidString)"
}
