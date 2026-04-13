//
//  QuizInstanceParticipant.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct QuizInstanceParticipant {
    let maxPossibleScore: Int?
    let reviewStatus: QuizReviewStatus?
    let sessionStatus: SessionStatus?
    let totalScore: Int?
    let userId: String?
}
