//
//  MainModels.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum ProfileModels {
    enum Row {
        case header(String)
        case notificationToggle(type: NotificationToggleType)
        case notificationDeadline
        case theme
        case language
        case divider
    }

    enum NotificationToggleType {
        case newQuiz
        case quizResults
        case groupInvites

        var title: String {
            switch self {
            case .newQuiz:
                return "newQuiz".localized
            case .quizResults:
                return "quizResults".localized
            case .groupInvites:
                return "groupInvitation".localized
            }
        }
    }

    enum DeadlineReminderOption: String, CaseIterable {
        case never = "never"
        case oneHour = "1h"
        case threeHours = "3h"
        case sixHours = "6h"
        case twelveHours = "12h"
        case oneDay = "24h"

        var title: String {
            switch self {
            case .never:
                return "never".localized
            case .oneHour:
                return "oneHourBefore".localized
            case .threeHours:
                return "threeHoursBefore".localized
            case .sixHours:
                return "sixHoursBefore".localized
            case .twelveHours:
                return "twelveHoursBefore".localized
            case .oneDay:
                return "oneDayBefore".localized
            }
        }
    }

    enum ThemeOption: String, CaseIterable {
        case system
        case light
        case dark

        var title: String {
            switch self {
            case .system:
                return "systemTheme".localized
            case .light:
                return "lightTheme".localized
            case .dark:
                return "darkTheme".localized
            }
        }

        var interfaceStyle: UIUserInterfaceStyle {
            switch self {
            case .system:
                return .unspecified
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }

        var themePreference: AppThemePreference {
            switch self {
            case .system:
                return .system
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }

        init(themePreference: AppThemePreference) {
            switch themePreference {
            case .system:
                self = .system
            case .light:
                self = .light
            case .dark:
                self = .dark
            }
        }
    }

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

    struct NotificationsSettings: Equatable {
        var deadlineReminder: DeadlineReminderOption
        var groupInvites: Bool
        var newQuizzes: Bool
        var quizResults: Bool

        static let `default` = NotificationsSettings(
            deadlineReminder: .never,
            groupInvites: false,
            newQuizzes: false,
            quizResults: false
        )
    }
}

// MARK: - NotificationsSettingsDTO Mapping
extension ProfileModels.NotificationsSettings {
    init(dto: NotificationsSettingsDTO) {
        self.init(
            deadlineReminder: ProfileModels.DeadlineReminderOption(rawValue: dto.deadlineReminder ?? "") ?? .never,
            groupInvites: dto.groupInvites ?? false,
            newQuizzes: dto.newQuizzes ?? false,
            quizResults: dto.quizResults ?? false
        )
    }
}
