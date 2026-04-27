//
//  TokenStoreTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Testing
@testable import Kollocol

struct TokenStoreTests {
    @Test
    func initialStateHasNoTokens() async {
        let store = TokenStore()

        #expect(await store.access() == nil)
        #expect(await store.refresh() == nil)
    }

    @Test
    func setStoresAccessAndRefreshTokens() async {
        let store = TokenStore()
        let pair = TokenPair(accessToken: "access-1", refreshToken: "refresh-1")

        await store.set(pair)

        #expect(await store.access() == "access-1")
        #expect(await store.refresh() == "refresh-1")
    }

    @Test
    func clearRemovesStoredTokens() async {
        let store = TokenStore()
        await store.set(TokenPair(accessToken: "access-2", refreshToken: "refresh-2"))

        await store.clear()

        #expect(await store.access() == nil)
        #expect(await store.refresh() == nil)
    }
}
