//
//  GeneratedQuestionDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GeneratedQuestionDTO: Decodable {
    let correctAnswer: QuestionCorrectAnswer?
    let maxScore: Int?
    let options: [String]?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?

    private enum CodingKeys: String, CodingKey {
        case correctAnswer = "correct_answer"
        case maxScore = "max_score"
        case options
        case text
        case timeLimitSec = "time_limit_sec"
        case type
    }
}

// MARK: - Decodable
extension GeneratedQuestionDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedType = try container.decodeEnumIfPresent(QuestionType.self, forKey: .type)
        type = decodedType
        correctAnswer = try decodedType.flatMap {
            try container.decodeQuestionCorrectAnswerIfPresent(
                forKey: .correctAnswer,
                questionType: $0
            )
        }
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        timeLimitSec = try container.decodeIfPresent(Int.self, forKey: .timeLimitSec)
    }
}

// MARK: - GeneratedQuestionDTO -> Question
extension GeneratedQuestionDTO {
    func toDomain() -> Question {
        Question(
            correctAnswer: correctAnswer,
            id: nil,
            maxScore: maxScore,
            options: options,
            text: text,
            timeLimitSec: timeLimitSec,
            type: type
        )
    }
}
