//
//  UserAnswerDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct UserAnswerDTO: Decodable {
    let answer: String?
    let isCorrect: Bool?
    let questionId: String?
    let score: Int?
    let timeSpentMs: Int?

    private enum CodingKeys: String, CodingKey {
        case answer
        case isCorrect = "is_correct"
        case questionId = "question_id"
        case score
        case timeSpentMs = "time_spent_ms"
    }
}

// MARK: - UserAnswerDTO -> QuizParticipantAnswer
extension UserAnswerDTO {
    func toDomain() -> QuizParticipantAnswer {
        return QuizParticipantAnswer(
            answer: self.answer,
            isCorrect: self.isCorrect,
            questionId: self.questionId,
            score: self.score,
            timeSpentMs: self.timeSpentMs
        )
    }
}

// MARK: - Decodable
extension UserAnswerDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let value = try container.decodeIfPresent(String.self, forKey: .answer) {
            answer = value
        } else if let value = try container.decodeIfPresent(Int.self, forKey: .answer) {
            answer = String(value)
        } else if let value = try container.decodeIfPresent([Int].self, forKey: .answer) {
            answer = value.map(String.init).joined(separator: ",")
        } else {
            answer = nil
        }

        isCorrect = try container.decodeIfPresent(Bool.self, forKey: .isCorrect)
        questionId = try container.decodeIfPresent(String.self, forKey: .questionId)
        score = try container.decodeIfPresent(Int.self, forKey: .score)
        timeSpentMs = try container.decodeIfPresent(Int.self, forKey: .timeSpentMs)
    }
}
