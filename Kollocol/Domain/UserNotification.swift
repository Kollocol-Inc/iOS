//
//  UserNotification.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct UserNotification {
    let content: String?
    let createdAt: Date?
    let id: String?
    let isRead: Bool?
    let relatedEntityId: String?
    let requiresAction: Bool?
    let title: String?
    let type: UserNotificationType
    let userId: String?
}

enum UserNotificationType: String {
    case groupInvite = "group_invite"
    case quizCreated = "quiz_created"
    case quizResults = "quiz_results"
    case gradeChanged = "grade_changed"
    case deadlineReminder = "deadline_reminder"
    case groupKicked = "group_kicked"
    case unknown
}
