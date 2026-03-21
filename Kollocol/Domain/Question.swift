//
//  Question.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

enum QuestionCorrectAnswer {
    case openText(String)
    case singleChoice(Int)
    case multipleChoice([Int])
}

struct Question {
    let correctAnswer: QuestionCorrectAnswer?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?
}

// MARK: - Question -> QuestionInputDTO
extension Question {
    func toDto() -> QuestionInputDto {
        return QuestionInputDto(
            correctAnswer: self.correctAnswer,
            maxScore: self.maxScore,
            options: self.options,
            text: self.text,
            timeLimitSec: self.timeLimitSec,
            type: self.type
        )
    }
}
