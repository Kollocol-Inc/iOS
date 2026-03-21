//
//  QuestionInputDto.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 10.03.2026.
//

import Foundation

struct QuestionInputDto: Encodable {
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

// MARK: - Encodable
extension QuestionInputDto {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try encodeCorrectAnswer(in: &container)
        try container.encodeIfPresent(maxScore, forKey: .maxScore)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(timeLimitSec, forKey: .timeLimitSec)
        try container.encodeIfPresent(type?.rawValue, forKey: .type)
    }

    private func encodeCorrectAnswer(
        in container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        guard let correctAnswer else { return }
        guard let type else {
            throw EncodingError.invalidValue(
                correctAnswer,
                EncodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.correctAnswer],
                    debugDescription: "Cannot encode `correct_answer` because `type` is missing."
                )
            )
        }

        switch (type, correctAnswer) {
        case (.singleChoice, .singleChoice(let index)):
            try container.encode(index, forKey: .correctAnswer)

        case (.multiChoice, .multipleChoice(let indexes)):
            try container.encode(indexes, forKey: .correctAnswer)

        case (.openEnded, .openText(let value)):
            try container.encode(value, forKey: .correctAnswer)

        default:
            throw EncodingError.invalidValue(
                correctAnswer,
                EncodingError.Context(
                    codingPath: container.codingPath + [CodingKeys.correctAnswer],
                    debugDescription: "Invalid `correct_answer` for type `\(type.rawValue)`."
                )
            )
        }
    }
}
