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
        case showCorrectAnswer  = "show_correct_answer"
        case timeLimitTotal     = "time_limit_total"
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
