//
//  QuestionDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct QuestionDTO: Decodable {
    let aiAnswer: String?
    let correctAnswer: String?
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
        correctAnswer = try container.decodeIfPresent(String.self, forKey: .correctAnswer)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        orderIndex = try container.decodeIfPresent(Int.self, forKey: .orderIndex)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        timeLimitSec = try container.decodeIfPresent(Int.self, forKey: .timeLimitSec)
        type = try container.decodeEnumIfPresent(QuestionType.self, forKey: .type)
    }
}
