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
        case divider
    }

    enum NotificationToggleType {
        case newQuiz
        case quizResults
        case groupInvites

        var title: String {
            switch self {
            case .newQuiz:
                return "Новый квиз"
            case .quizResults:
                return "Результаты квиза"
            case .groupInvites:
                return "Приглашение в группу"
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
                return "Никогда"
            case .oneHour:
                return "За час"
            case .threeHours:
                return "За 3 часа"
            case .sixHours:
                return "За 6 часов"
            case .twelveHours:
                return "За 12 часов"
            case .oneDay:
                return "За сутки"
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
                return "Системная"
            case .light:
                return "Светлая"
            case .dark:
                return "Темная"
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
