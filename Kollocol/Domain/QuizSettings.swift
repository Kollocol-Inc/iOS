//
//  QuizSettings.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct QuizSettings {
    let allowReview:        Bool?
    let randomOrder:        Bool?
    let showCorrectAnswer:  Bool?
    let timeLimitTotal:     Bool?
}

// MARK: - QuizSettings -> QuizSettingsDTO
extension QuizSettings {
    func toDto() -> QuizSettingsDTO {
        return QuizSettingsDTO(
            allowReview: self.allowReview,
            randomOrder: self.randomOrder,
            showCorrectAnswer: self.showCorrectAnswer,
            timeLimitTotal: self.timeLimitTotal
        )
    }
}
