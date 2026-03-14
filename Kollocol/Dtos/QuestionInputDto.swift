//
//  QuestionInputDto.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 10.03.2026.
//

import Foundation

struct QuestionInputDto: Encodable {
    let correctAnswers: [String]?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let orderIndex: Int?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?

    private enum CodingKeys: String, CodingKey {
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

// MARK: - Encodable
extension QuestionInputDto {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(correctAnswers, forKey: .correctAnswers)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(maxScore, forKey: .maxScore)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(orderIndex, forKey: .orderIndex)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(timeLimitSec, forKey: .timeLimitSec)
        try container.encodeIfPresent(type?.rawValue, forKey: .type)
    }
}
