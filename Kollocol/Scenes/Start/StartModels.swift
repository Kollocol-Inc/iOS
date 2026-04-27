//
//  Models.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

enum StartModels {
    enum LanguageOption: String, CaseIterable {
        case system
        case russian
        case english

        var title: String {
            switch self {
            case .system:
                return "systemLanguage".localized
            case .russian:
                return "russianLanguage".localized
            case .english:
                return "English"
            }
        }

        var languagePreference: AppLanguagePreference {
            switch self {
            case .system:
                return .system
            case .russian:
                return .ru
            case .english:
                return .en
            }
        }

        init(languagePreference: AppLanguagePreference) {
            switch languagePreference {
            case .system:
                self = .system
            case .ru:
                self = .russian
            case .en:
                self = .english
            }
        }
    }
}
