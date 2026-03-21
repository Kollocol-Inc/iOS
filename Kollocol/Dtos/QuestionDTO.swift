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
        correctAnswer = try QuestionDTO.decodeCorrectAnswer(from: container, questionType: resolvedType)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        maxScore = try container.decodeIfPresent(Int.self, forKey: .maxScore)
        options = try container.decodeIfPresent([String].self, forKey: .options)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        timeLimitSec = try container.decodeIfPresent(Int.self, forKey: .timeLimitSec)
    }
}

private extension QuestionDTO {
    private static func decodeCorrectAnswer(
        from container: KeyedDecodingContainer<CodingKeys>,
        questionType: QuestionType
    ) throws -> QuestionCorrectAnswer? {
        guard container.contains(.correctAnswer) else { return nil }
        if try container.decodeNil(forKey: .correctAnswer) {
            return nil
        }

        switch questionType {
        case .singleChoice:
            if let value = try container.decodeIfPresent(Int.self, forKey: .correctAnswer) {
                return .singleChoice(value)
            }
            throw correctAnswerMismatchError(
                expected: "Int (index for single_choice)",
                actual: actualJSONTypeDescription(from: container),
                codingPath: container.codingPath + [CodingKeys.correctAnswer]
            )

        case .multiChoice:
            if let value = try container.decodeIfPresent([Int].self, forKey: .correctAnswer) {
                return .multipleChoice(value)
            }
            throw correctAnswerMismatchError(
                expected: "[Int] (indexes for multiple_choice)",
                actual: actualJSONTypeDescription(from: container),
                codingPath: container.codingPath + [CodingKeys.correctAnswer]
            )

        case .openEnded:
            if let value = try container.decodeIfPresent(String.self, forKey: .correctAnswer) {
                return .openText(value)
            }
            throw correctAnswerMismatchError(
                expected: "String (text for open)",
                actual: actualJSONTypeDescription(from: container),
                codingPath: container.codingPath + [CodingKeys.correctAnswer]
            )
        }
    }

    private static func correctAnswerMismatchError(
        expected: String,
        actual: String,
        codingPath: [CodingKey]
    ) -> DecodingError {
        DecodingError.typeMismatch(
            QuestionCorrectAnswer.self,
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Invalid value for `correct_answer`. Expected \(expected), but got \(actual)."
            )
        )
    }

    private static func actualJSONTypeDescription(
        from container: KeyedDecodingContainer<CodingKeys>
    ) -> String {
        if (try? container.decodeNil(forKey: .correctAnswer)) == true {
            return "null"
        }
        if (try? container.decode(Int.self, forKey: .correctAnswer)) != nil {
            return "Int"
        }
        if (try? container.decode([Int].self, forKey: .correctAnswer)) != nil {
            return "[Int]"
        }
        if (try? container.decode(String.self, forKey: .correctAnswer)) != nil {
            return "String"
        }
        if (try? container.decode([String].self, forKey: .correctAnswer)) != nil {
            return "[String]"
        }
        if (try? container.decode(Double.self, forKey: .correctAnswer)) != nil {
            return "Double"
        }
        if (try? container.decode(Bool.self, forKey: .correctAnswer)) != nil {
            return "Bool"
        }
        return "unknown JSON type"
    }
}
