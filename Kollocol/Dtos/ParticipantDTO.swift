//
//  ParticipantDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct ParticipantDTO: Decodable {
    let maxPossibleScore: Int?
    let reviewStatus: QuizReviewStatus?
    let sessionStatus: SessionStatus?
    let totalScore: Int?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case maxPossibleScore = "max_possible_score"
        case reviewStatus = "review_status"
        case sessionStatus = "session_status"
        case totalScore = "total_score"
        case userId = "user_id"
    }
}

// MARK: - ParticipantDTO -> QuizInstanceParticipant
extension ParticipantDTO {
    func toDomain() -> QuizInstanceParticipant {
        return QuizInstanceParticipant(
            maxPossibleScore: self.maxPossibleScore,
            reviewStatus: self.reviewStatus,
            sessionStatus: self.sessionStatus,
            totalScore: self.totalScore,
            userId: self.userId
        )
    }
}

// MARK: - Decodable
extension ParticipantDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        maxPossibleScore = try container.decodeIfPresent(Int.self, forKey: .maxPossibleScore)
        reviewStatus = try container.decodeEnumIfPresent(QuizReviewStatus.self, forKey: .reviewStatus)
        sessionStatus = try container.decodeEnumIfPresent(SessionStatus.self, forKey: .sessionStatus)
        totalScore = try container.decodeIfPresent(Int.self, forKey: .totalScore)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}
