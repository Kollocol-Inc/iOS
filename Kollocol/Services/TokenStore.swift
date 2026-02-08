//
//  TokenStore.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

actor TokenStore {
    private var accessToken: String?
    private var refreshToken: String?

    func set(_ pair: TokenPair) {
        accessToken = pair.accessToken
        refreshToken = pair.refreshToken
    }

    func access() -> String? {
        accessToken
    }

    func refresh() -> String? {
        refreshToken
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}
