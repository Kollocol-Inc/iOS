//
//  QuizInstanceParticipant.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct QuizInstanceParticipant {
    let avatarURL: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let maxPossibleScore: Int?
    let reviewStatus: QuizReviewStatus?
    let sessionStatus: SessionStatus?
    let totalScore: Int?
    let userId: String?
}
