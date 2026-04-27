//
//  String+Localization.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 25.04.2026.
//

import Foundation

extension String {
    var localized: String {
        let preferredLanguage = UserDefaults.standard
            .string(forKey: UserDefaultsKey.appLanguagePreference.rawValue)
            .flatMap(AppLanguagePreference.init(rawValue:))

        let bundle: Bundle = {
            guard let localeIdentifier = preferredLanguage?.localeIdentifier,
                  let path = Bundle.main.path(forResource: localeIdentifier, ofType: "lproj"),
                  let languageBundle = Bundle(path: path) else {
                return .main
            }
            return languageBundle
        }()

        let localizedValue = NSLocalizedString(
            self,
            tableName: "localization",
            bundle: bundle,
            value: self,
            comment: ""
        )

        // Support escaped newlines stored in localization values (e.g. "\\n").
        return localizedValue.replacingOccurrences(of: "\\n", with: "\n")
    }
}
