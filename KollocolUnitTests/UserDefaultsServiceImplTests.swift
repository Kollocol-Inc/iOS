//
//  UserDefaultsServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct UserDefaultsServiceImplTests {
    @Test
    func setAndValueRoundTripForGenericValue() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        context.service.set("dark", for: .appThemePreference)

        let value: String? = context.service.value(for: .appThemePreference)
        #expect(value == "dark")
        #expect(context.service.exists(.appThemePreference))
    }

    @Test
    func setNilRemovesStoredValue() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        context.service.set("en", for: .appLanguagePreference)
        let nilValue: String? = nil
        context.service.set(nilValue, for: .appLanguagePreference)

        let value: String? = context.service.value(for: .appLanguagePreference)
        #expect(value == nil)
        #expect(context.service.exists(.appLanguagePreference) == false)
    }

    @Test
    func removeDeletesStoredValue() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        context.service.set(true, for: .isRegistered)
        #expect(context.service.exists(.isRegistered))

        context.service.remove(.isRegistered)

        #expect(context.service.exists(.isRegistered) == false)
        #expect(context.service.isRegistered == false)
    }

    @Test
    func isRegisteredDefaultsToFalseAndPersistsAssignedValue() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        #expect(context.service.isRegistered == false)

        context.service.isRegistered = true

        #expect(context.service.isRegistered == true)
        let storedRaw: Bool? = context.service.value(for: .isRegistered)
        #expect(storedRaw == true)
    }

    @Test
    func appThemePreferenceUsesSystemAsFallback() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        #expect(context.service.appThemePreference == .system)

        context.service.appThemePreference = .dark
        #expect(context.service.appThemePreference == .dark)

        context.defaults.set("invalid_theme", forKey: UserDefaultsKey.appThemePreference.rawValue)
        #expect(context.service.appThemePreference == .system)
    }

    @Test
    func appLanguagePreferenceUsesSystemAsFallbackAndLocaleIdentifiersAreCorrect() {
        let context = makeIsolatedUserDefaultsContext()
        defer { context.cleanup() }

        #expect(context.service.appLanguagePreference == .system)

        context.service.appLanguagePreference = .ru
        #expect(context.service.appLanguagePreference == .ru)
        #expect(context.service.appLanguagePreference.localeIdentifier == "ru")

        context.service.appLanguagePreference = .en
        #expect(context.service.appLanguagePreference == .en)
        #expect(context.service.appLanguagePreference.localeIdentifier == "en")

        context.defaults.set("invalid_language", forKey: UserDefaultsKey.appLanguagePreference.rawValue)
        #expect(context.service.appLanguagePreference == .system)
        #expect(context.service.appLanguagePreference.localeIdentifier == nil)
    }
}

private struct UserDefaultsTestContext {
    let suiteName: String
    let defaults: UserDefaults
    let service: UserDefaultsServiceImpl

    func cleanup() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

private func makeIsolatedUserDefaultsContext() -> UserDefaultsTestContext {
    let suiteName = "UserDefaultsServiceImplTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)

    return UserDefaultsTestContext(
        suiteName: suiteName,
        defaults: defaults,
        service: UserDefaultsServiceImpl(defaults: defaults)
    )
}
