//
//  KeychainClientTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct KeychainClientTests {
    @Test
    func readMissingValueReturnsNil() throws {
        let client = KeychainClient(service: makeUniqueKeychainService())
        let account = "missing-\(UUID().uuidString)"

        try client.delete(account: account)

        let value = try client.read(account: account)

        #expect(value == nil)
    }

    @Test
    func writeReadDeleteRoundTrip() throws {
        let client = KeychainClient(service: makeUniqueKeychainService())
        let account = "round-trip-\(UUID().uuidString)"
        let payload = Data("secret-1".utf8)

        try client.delete(account: account)
        try client.write(payload, account: account)
        let readBack = try client.read(account: account)

        #expect(readBack == payload)

        try client.delete(account: account)
        let afterDelete = try client.read(account: account)
        #expect(afterDelete == nil)
    }

    @Test
    func writeOverridesExistingValueForSameAccount() throws {
        let client = KeychainClient(service: makeUniqueKeychainService())
        let account = "overwrite-\(UUID().uuidString)"

        try client.delete(account: account)
        try client.write(Data("first".utf8), account: account)
        try client.write(Data("second".utf8), account: account)

        let readBack = try client.read(account: account)
        #expect(readBack == Data("second".utf8))
    }

    @Test
    func deletingMissingAccountDoesNotThrow() throws {
        let client = KeychainClient(service: makeUniqueKeychainService())
        let account = "delete-missing-\(UUID().uuidString)"

        try client.delete(account: account)
        try client.delete(account: account)
    }
}

private func makeUniqueKeychainService() -> String {
    "com.kollocol.tests.keychain.\(UUID().uuidString)"
}
