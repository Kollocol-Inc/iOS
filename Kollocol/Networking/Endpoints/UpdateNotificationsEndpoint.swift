//
//  UpdateNotifications.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import Foundation

struct UpdateNotificationsEndpoint: Endpoint {
    typealias Response = NotificationsSettingsDTO

    let deadlineReminder: String
    let groupInvites: Bool
    let newQuizzes: Bool
    let quizResults: Bool

    var method: HTTPMethod { .put }
    var path: String { "/users/me/notifications" }
    var body: AnyEncodable? {
        AnyEncodable(
            Body(
                deadlineReminder: deadlineReminder,
                groupInvites: groupInvites,
                newQuizzes: newQuizzes,
                quizResults: quizResults
            )
        )
    }
    var multipart: MultipartFormData? { nil }

    struct Body: Encodable, Sendable {
        let deadlineReminder: String
        let groupInvites: Bool
        let newQuizzes: Bool
        let quizResults: Bool

        private enum CodingKeys: String, CodingKey {
            case deadlineReminder = "deadline_reminder"
            case groupInvites = "group_invites"
            case newQuizzes = "new_quizzes"
            case quizResults = "quiz_results"
        }
    }
}
