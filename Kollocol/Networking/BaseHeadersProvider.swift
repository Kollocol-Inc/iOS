//
//  BaseHeadersProvider.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

// MARK: - BaseHeadersProvider
protocol BaseHeadersProvider {
    func headers() -> [String: String]
}

// MARK: - BaseHeadersProviderImpl
final class BaseHeadersProviderImpl: BaseHeadersProvider {
    // MARK: - Constants
    private enum Constants {
        static let acceptLanguageHeader = "X-Accept-Language"
        static let platformHeader = "X-Platform"
        static let platformValue = "ios"
        static let englishLanguageCode = "en"
        static let russianLanguageCode = "ru"
    }

    // MARK: - Properties
    private let udService: UserDefaultsService
    private let preferredLanguageIdentifiersProvider: () -> [String]

    // MARK: - Lifecycle
    init(
        udService: UserDefaultsService,
        preferredLanguageIdentifiersProvider: @escaping () -> [String] = { Locale.preferredLanguages }
    ) {
        self.udService = udService
        self.preferredLanguageIdentifiersProvider = preferredLanguageIdentifiersProvider
    }

    // MARK: - Methods
    func headers() -> [String: String] {
        [
            Constants.acceptLanguageHeader: resolveLanguageHeaderValue(),
            Constants.platformHeader: Constants.platformValue
        ]
    }

    // MARK: - Private Methods
    private func resolveLanguageHeaderValue() -> String {
        switch udService.appLanguagePreference {
        case .ru:
            return Constants.russianLanguageCode
        case .en:
            return Constants.englishLanguageCode
        case .system:
            return resolveSystemLanguageHeaderValue()
        }
    }

    private func resolveSystemLanguageHeaderValue() -> String {
        guard let languageIdentifier = preferredLanguageIdentifiersProvider().first else {
            return Constants.englishLanguageCode
        }

        let code = languageIdentifier
            .split(whereSeparator: { $0 == "-" || $0 == "_" })
            .first?
            .lowercased()

        if code == Constants.russianLanguageCode {
            return Constants.russianLanguageCode
        }

        return Constants.englishLanguageCode
    }
}
