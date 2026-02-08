//
//  KeychainTokenStore.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

actor KeychainTokenStore: TokenStoring {
    private let keychain: KeychainClient
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"

    init(service: String) {
        keychain = KeychainClient(service: service)
    }

    func accessToken() async -> String? {
        guard let data = try? keychain.read(account: accessKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func refreshToken() async -> String? {
        guard let data = try? keychain.read(account: refreshKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func set(_ pair: TokenPair) async {
        _ = try? keychain.write(Data(pair.accessToken.utf8), account: accessKey)
        _ = try? keychain.write(Data(pair.refreshToken.utf8), account: refreshKey)
    }

    func clear() async {
        _ = try? keychain.delete(account: accessKey)
        _ = try? keychain.delete(account: refreshKey)
    }
}
