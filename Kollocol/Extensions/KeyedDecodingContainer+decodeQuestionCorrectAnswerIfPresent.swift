//
//  KeyedDecodingContainer+decodeQuestionCorrectAnswerIfPresent.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeQuestionCorrectAnswerIfPresent(
        forKey key: Key,
        questionType: QuestionType
    ) throws -> QuestionCorrectAnswer? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }

        switch questionType {
        case .singleChoice:
            if let value = try decodeIfPresent(Int.self, forKey: key) {
                return .singleChoice(value)
            }
            throw questionCorrectAnswerMismatchError(
                expected: "Int (index for single)",
                actual: actualJSONTypeDescription(forKey: key),
                codingPath: codingPath + [key]
            )

        case .multiChoice:
            if let value = try decodeIfPresent([Int].self, forKey: key) {
                return .multipleChoice(value)
            }
            throw questionCorrectAnswerMismatchError(
                expected: "[Int] (indexes for multiple)",
                actual: actualJSONTypeDescription(forKey: key),
                codingPath: codingPath + [key]
            )

        case .openEnded:
            if let value = try decodeIfPresent(String.self, forKey: key) {
                return .openText(value)
            }
            throw questionCorrectAnswerMismatchError(
                expected: "String (text for open)",
                actual: actualJSONTypeDescription(forKey: key),
                codingPath: codingPath + [key]
            )
        }
    }

    private func questionCorrectAnswerMismatchError(
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

    private func actualJSONTypeDescription(forKey key: Key) -> String {
        if (try? decodeNil(forKey: key)) == true {
            return "null"
        }
        if (try? decode(Int.self, forKey: key)) != nil {
            return "Int"
        }
        if (try? decode([Int].self, forKey: key)) != nil {
            return "[Int]"
        }
        if (try? decode(String.self, forKey: key)) != nil {
            return "String"
        }
        if (try? decode([String].self, forKey: key)) != nil {
            return "[String]"
        }
        if (try? decode(Double.self, forKey: key)) != nil {
            return "Double"
        }
        if (try? decode(Bool.self, forKey: key)) != nil {
            return "Bool"
        }
        return "unknown JSON type"
    }
}
