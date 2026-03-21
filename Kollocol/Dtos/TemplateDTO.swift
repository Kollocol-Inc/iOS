//
//  TemplateDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct TemplateDTO: Decodable {
    let createdAt: Date?
    let description: String?
    let id: String?
    let questions: [QuestionDTO]?
    let quizType: QuizType?
    let settings: QuizSettingsDTO?
    let title: String?
    let updatedAt: Date?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case description
        case id
        case questions
        case quizType = "quiz_type"
        case settings
        case title
        case updatedAt = "updated_at"
        case userId = "user_id"
    }
}

// MARK: - TemplateDTO -> QuizTemplate
extension TemplateDTO {
    func toDomain() -> QuizTemplate {
        return QuizTemplate(
            createdAt: self.createdAt,
            description: self.description,
            id: self.id,
            questions: self.questions?.map { $0.toDomain() },
            quizType: self.quizType,
            settings: self.settings?.toDomain(),
            title: self.title,
            updatedAt: self.updatedAt,
            userId: self.userId
        )
    }
}

// MARK: - Decodable
extension TemplateDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)

        description = try container.decodeIfPresent(String.self, forKey: .description)
        id = try container.decodeIfPresent(String.self, forKey: .id)

        questions = try container.decodeIfPresent([QuestionDTO].self, forKey: .questions)

        quizType = try container.decodeEnumIfPresent(QuizType.self, forKey: .quizType)
        settings = try container.decodeIfPresent(QuizSettingsDTO.self, forKey: .settings)
        title = try container.decodeIfPresent(String.self, forKey: .title)

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = try Self.parseRFC3339(updatedAtString, key: .updatedAt)

        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}

// MARK: - Constants
private extension TemplateDTO {
    private enum Constants {
        static let rfc3339WithFractionalSeconds: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()

        static let rfc3339: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }()
    }
}

// MARK: - Private Methods
private extension TemplateDTO {
    private static func parseRFC3339(_ value: String, key: CodingKeys) throws -> Date {
        if let date = Constants.rfc3339WithFractionalSeconds.date(from: value) {
            return date
        }
        if let date = Constants.rfc3339.date(from: value) {
            return date
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: [key],
                debugDescription: "Invalid RFC3339 date: \(value)"
            )
        )
    }
}
