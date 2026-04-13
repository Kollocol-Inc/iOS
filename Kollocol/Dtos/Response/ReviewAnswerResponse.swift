//
//  ReviewAnswerResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct ReviewAnswerResponse: Decodable {
    let feedback: String?
    let suggestedScore: Int?

    private enum CodingKeys: String, CodingKey {
        case feedback
        case suggestedScore = "suggested_score"
    }
}

// MARK: - ReviewAnswerResponse -> QuizAnswerReviewSuggestion
extension ReviewAnswerResponse {
    func toDomain() -> QuizAnswerReviewSuggestion {
        return QuizAnswerReviewSuggestion(
            feedback: self.feedback,
            suggestedScore: self.suggestedScore
        )
    }
}
