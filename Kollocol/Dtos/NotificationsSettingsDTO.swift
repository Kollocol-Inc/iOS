//
//  NotificationsSettingsDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import Foundation

struct NotificationsSettingsDTO: Decodable {
    let deadlineReminder: String?
    let groupInvites: Bool?
    let newQuizzes: Bool?
    let quizResults: Bool?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case deadlineReminder = "deadline_reminder"
        case groupInvites = "group_invites"
        case newQuizzes = "new_quizzes"
        case quizResults = "quiz_results"
        case userId = "user_id"
    }
}
