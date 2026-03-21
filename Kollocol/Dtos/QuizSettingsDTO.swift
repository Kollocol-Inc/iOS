//
//  QuizSettingsDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct QuizSettingsDTO: Codable {
    let allowReview:        Bool?
    let randomOrder:        Bool?
    let showCorrectAnswer:  Bool?
    let timeLimitTotal:     Bool?

    private enum CodingKeys: String, CodingKey {
        case allowReview        = "allow_review"
        case randomOrder        = "random_order"
        case questionsRandomOrder = "questions_random_order"
        case showCorrectAnswer  = "show_correct_answer"
        case timeLimitTotal     = "time_limit_total"
    }
}

// MARK: - Codable
extension QuizSettingsDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        allowReview = try container.decodeIfPresent(Bool.self, forKey: .allowReview)

        if let questionsRandomOrder = try container.decodeIfPresent(Bool.self, forKey: .questionsRandomOrder) {
            randomOrder = questionsRandomOrder
        } else {
            randomOrder = try container.decodeIfPresent(Bool.self, forKey: .randomOrder)
        }

        showCorrectAnswer = try container.decodeIfPresent(Bool.self, forKey: .showCorrectAnswer)
        timeLimitTotal = try container.decodeIfPresent(Bool.self, forKey: .timeLimitTotal)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(allowReview, forKey: .allowReview)
        try container.encodeIfPresent(randomOrder, forKey: .questionsRandomOrder)
        try container.encodeIfPresent(randomOrder, forKey: .randomOrder)
        try container.encodeIfPresent(showCorrectAnswer, forKey: .showCorrectAnswer)
        try container.encodeIfPresent(timeLimitTotal, forKey: .timeLimitTotal)
    }
}

// MARK: - QuizSettingsDTO -> QuizSettings
extension QuizSettingsDTO {
    func toDomain() -> QuizSettings {
        return QuizSettings(
            allowReview: self.allowReview,
            randomOrder: self.randomOrder,
            showCorrectAnswer: self.showCorrectAnswer,
            timeLimitTotal: self.timeLimitTotal
        )
    }
}
