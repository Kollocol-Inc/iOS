//
//  ReviewAnswerRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct ReviewAnswerRequestDTO: Encodable {
    let participantId: String
    let questionId: String

    private enum CodingKeys: String, CodingKey {
        case participantId = "participant_id"
        case questionId = "question_id"
    }
}

// MARK: - ReviewAnswerRequest -> ReviewAnswerRequestDTO
extension ReviewAnswerRequest {
    func toDto() -> ReviewAnswerRequestDTO {
        return ReviewAnswerRequestDTO(
            participantId: self.participantId,
            questionId: self.questionId
        )
    }
}
