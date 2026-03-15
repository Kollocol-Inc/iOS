//
//  QuestionDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct QuestionDTO: Decodable {
    let aiAnswer: String?
    let correctAnswer: QuestionCorrectAnswer?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let orderIndex: Int?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?

    private enum CodingKeys: String, CodingKey {
        case aiAnswer = "ai_answer"
        case correctAnswer = "correct_answer"
        case correctAnswers = "correct_answers"
        case id
        case maxScore = "max_score"
        case options
        case orderIndex = "order_index"
        case text
        case timeLimitSec = "time_limit_sec"
        case type 
    }
}

// MARK: - QuestionDTO -> Question
extension QuestionDTO {
    func toDomain() -> Question {
        return Question(
            aiAnswer: self.aiAnswer,
            correctAnswer: self.correctAnswer,
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

// MARK: - Decodable
extension QuestionDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        aiAnswer = try container.decodeIfPresent(String.self, forKey: .aiAnswer)

        if let answerIndexes = try container.decodeIfPresent([Int].self, forKey: .correctAnswer) {
            correctAnswer = .multipleChoice(answerIndexes)
        } else if let answerIndex = try container.decodeIfPresent(Int.self, forKey: .correctAnswer) {
            correctAnswer = .singleChoice(answerIndex)
        } else if let answerText = try container.decodeIfPresent(String.self, forKey: .correctAnswer) {
            correctAnswer = .openText(answerText)
        } else if let legacyAnswers = try container.decodeIfPresent([String].self, forKey: .correctAnswers) {
            if legacyAnswers.count == 1, let index = Int(legacyAnswers[0]) {
                correctAnswer = .singleChoice(index)
            } else if legacyAnswers.allSatisfy({ Int($0) != nil }) {
                correctAnswer = .multipleChoice(legacyAnswers.compactMap(Int.init))
            } else if let first = legacyAnswers.first {
                correctAnswer = .openText(first)
            } else {
                correctAnswer = nil
            }
        } else {
            correctAnswer = nil
        }

        id = try container.decodeIfPresent(String.self, forKey: .id)
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        timeLimitSec = try container.decodeIfPresent(Int.self, forKey: .timeLimitSec)
        type = try container.decodeEnumIfPresent(QuestionType.self, forKey: .type)
    }
}
