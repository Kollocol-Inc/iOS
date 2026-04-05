//
//  QuestionDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct QuestionDTO: Decodable {
    let correctAnswer: QuestionCorrectAnswer?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?

    private enum CodingKeys: String, CodingKey {
        case correctAnswer = "correct_answer"
        case id
        case maxScore = "max_score"
        case options
        case text
        case timeLimitSec = "time_limit_sec"
        case type 
    }
}

// MARK: - QuestionDTO -> Question
extension QuestionDTO {
    func toDomain() -> Question {
        return Question(
            correctAnswer: self.correctAnswer,
            id: self.id,
            maxScore: self.maxScore,
            options: self.options,
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

        let decodedType = try container.decodeEnumIfPresent(QuestionType.self, forKey: .type)
        guard let resolvedType = decodedType else {
            if container.contains(.type) {
                let rawValue = try container.decodeIfPresent(String.self, forKey: .type)
                if let rawValue {
                    throw DecodingError.dataCorruptedError(
                        forKey: .type,
                        in: container,
                        debugDescription: "Invalid `type` value '\(rawValue)'. Expected one of: open, single_choice, multiple_choice."
                    )
                } else {
                    throw DecodingError.valueNotFound(
                        QuestionType.self,
                        DecodingError.Context(
                            codingPath: container.codingPath + [CodingKeys.type],
                            debugDescription: "Missing required `type` value (null)."
                        )
                    )
                }
            }

            throw DecodingError.keyNotFound(
                CodingKeys.type,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Missing required key `type` for question decoding."
                )
            )
        }
        type = resolvedType
        correctAnswer = try container.decodeQuestionCorrectAnswerIfPresent(
            forKey: .correctAnswer,
            questionType: resolvedType
        )

        id = try container.decodeIfPresent(String.self, forKey: .id)
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        timeLimitSec = try container.decodeIfPresent(Int.self, forKey: .timeLimitSec)
    }
}
