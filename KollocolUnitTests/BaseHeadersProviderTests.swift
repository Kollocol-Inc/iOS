//
//  BaseHeadersProviderTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct BaseHeadersProviderTests {
    @Test
    func headersUseRussianForExplicitRussianPreference() {
        let udService = BaseHeadersUserDefaultsMock()
        udService.appLanguagePreference = .ru
        let provider = BaseHeadersProviderImpl(udService: udService)

        let headers = provider.headers()
        #expect(headers["X-Accept-Language"] == "ru")
        #expect(headers["X-Platform"] == "ios")
    }

    @Test
    func headersUseEnglishFallbackForUnsupportedSystemLanguage() {
        let udService = BaseHeadersUserDefaultsMock()
        udService.appLanguagePreference = .system
        let provider = BaseHeadersProviderImpl(
            udService: udService,
            preferredLanguageIdentifiersProvider: { ["fr_FR"] }
        )

        let headers = provider.headers()
        #expect(headers["X-Accept-Language"] == "en")
        #expect(headers["X-Platform"] == "ios")
    }

    @Test
    func headersUseRussianForSystemRussianLanguage() {
        let udService = BaseHeadersUserDefaultsMock()
        udService.appLanguagePreference = .system
        let provider = BaseHeadersProviderImpl(
            udService: udService,
            preferredLanguageIdentifiersProvider: { ["ru_RU"] }
        )

        let headers = provider.headers()
        #expect(headers["X-Accept-Language"] == "ru")
    }
}

private final class BaseHeadersUserDefaultsMock: UserDefaultsService {
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
