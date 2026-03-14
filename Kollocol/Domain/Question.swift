//
//  Question.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct Question {
    let aiAnswer: String?
    let correctAnswers: [String]?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let orderIndex: Int?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?
}

// MARK: - Question -> QuestionInputDTO
extension Question {
    func toDto() -> QuestionInputDto {
        QuestionInputDto(
            correctAnswers: self.correctAnswers,
            id: self.id,
            maxScore: self.maxScore,
            options: self.options,
            orderIndex: self.orderIndex,
            text: self.text,
            timeLimitSec: self.timeLimitSec,
            type: self.type
        )
    }
}
