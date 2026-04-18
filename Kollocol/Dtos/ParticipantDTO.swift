//
//  ParticipantDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct ParticipantDTO: Decodable {
    let avatarURL: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let maxPossibleScore: Int?
    let reviewStatus: QuizReviewStatus?
    let sessionStatus: SessionStatus?
    let totalScore: Int?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case avatarURL = "avatar_url"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case maxPossibleScore = "max_possible_score"
        case reviewStatus = "review_status"
        case sessionStatus = "session_status"
        case totalScore = "total_score"
        case userId = "user_id"
        case user
    }

    private struct UserPayload: Decodable {
        let avatarURL: String?
        let email: String?
        let firstName: String?
        let lastName: String?
        let id: String?

        private enum CodingKeys: String, CodingKey {
            case avatarURL = "avatar_url"
            case email
            case firstName = "first_name"
            case lastName = "last_name"
            case id
        }
    }
}

// MARK: - ParticipantDTO -> QuizInstanceParticipant
extension ParticipantDTO {
    func toDomain() -> QuizInstanceParticipant {
        return QuizInstanceParticipant(
            avatarURL: self.avatarURL,
            email: self.email,
            firstName: self.firstName,
            lastName: self.lastName,
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
        let user = try container.decodeIfPresent(UserPayload.self, forKey: .user)

        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL) ?? user?.avatarURL
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? user?.email
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? user?.firstName
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName) ?? user?.lastName
        maxPossibleScore = try container.decodeIfPresent(Int.self, forKey: .maxPossibleScore)
        reviewStatus = try container.decodeEnumIfPresent(QuizReviewStatus.self, forKey: .reviewStatus)
        sessionStatus = try container.decodeEnumIfPresent(SessionStatus.self, forKey: .sessionStatus)
        totalScore = try container.decodeIfPresent(Int.self, forKey: .totalScore)
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? user?.id
    }
}
