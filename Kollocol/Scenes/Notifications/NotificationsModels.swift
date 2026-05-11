//
//  NotificationsModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import Foundation

enum NotificationsModels {
    enum Row {
        case notification(NotificationViewData)
        case empty(String)
        case divider
    }

    struct NotificationViewData: Equatable {
        let id: String
        let relatedEntityId: String?
        let title: String
        let description: String
        let type: NotificationType
        let isRead: Bool
        let createdAt: Date?
        let dateText: String?
        let inviteActionState: InviteActionState
        let isInviteActionInProgress: Bool
    }

    enum InviteActionState: Equatable {
        case available
        case ignored
    }

    enum NotificationType: Equatable {
        case groupInvite
        case quizCreated
        case quizResults
        case gradeChanged
        case deadlineReminder
        case groupKicked
        case unknown
    }

    enum InviteAction {
        case accept
        case ignore
    }
}
