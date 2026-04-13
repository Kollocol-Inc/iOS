//
//  GradeAnswerRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GradeAnswerRequestDTO: Encodable {
    let participantId: String
    let questionId: String
    let score: Int?

    private enum CodingKeys: String, CodingKey {
        case participantId = "participant_id"
        case questionId = "question_id"
        case score
    }
}

// MARK: - GradeAnswerRequest -> GradeAnswerRequestDTO
extension GradeAnswerRequest {
    func toDto() -> GradeAnswerRequestDTO {
        return GradeAnswerRequestDTO(
            participantId: self.participantId,
            questionId: self.questionId,
            score: self.score
        )
    }
}
