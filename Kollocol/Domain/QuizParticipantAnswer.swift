//
//  QuizParticipantAnswer.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct QuizParticipantAnswer {
    let answer: String?
    let isCorrect: Bool?
    let isReviewed: Bool?
    let questionId: String?
    let score: Int?
    let timeSpentMs: Int?
}
