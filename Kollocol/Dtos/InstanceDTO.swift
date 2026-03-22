//
//  InstanceDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct InstanceDTO: Decodable {
    let accessCode:     String?
    let createdAt:      Date?
    let deadline:       Date?
    let groupId:        String?
    let hostUserId:     String?
    let id:             String?
    let quizType:       QuizType?
    let settings:       QuizSettingsDTO?
    let status:         QuizStatus?
    let templateId:     String?
    let title:          String?
    let totalQuestions: String?
    let totalTime:      String?

    private enum CodingKeys: String, CodingKey {
        case accessCode     = "access_code"
        case createdAt      = "created_at"
        case deadline
        case groupId        = "group_id"
        case hostUserId     = "host_user_id"
        case id
        case quizType       = "quiz_type"
        case settings
        case status
        case templateId     = "template_id"
        case title
        case totalQuestions = "total_questions"
        case totalTime      = "total_time"
    }
}

// MARK: - InstanceDTO -> Instance
extension InstanceDTO {
    func toDomain() -> QuizInstance {
        return QuizInstance(
            accessCode: self.accessCode,
            createdAt: self.createdAt,
            deadline: self.deadline,
            groupId: self.groupId,
            hostUserId: self.hostUserId,
            id: self.id,
            quizType: self.quizType,
            settings: self.settings?.toDomain(),
            status: self.status,
            templateId: self.templateId,
            title: self.title,
            totalQuestions: self.totalQuestions,
            totalTime: self.totalTime
        )
    }
}

// MARK: - Decodable
extension InstanceDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        accessCode = try container.decodeIfPresent(String.self, forKey: .accessCode)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)

        if let deadlineString = try container.decodeIfPresent(String.self, forKey: .deadline) {
            deadline = try Self.parseRFC3339(deadlineString, key: .deadline)
        } else {
            deadline = nil
        }

        groupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        hostUserId = try container.decodeIfPresent(String.self, forKey: .hostUserId)
        id = try container.decode(String.self, forKey: .id)
        
        quizType = try container.decodeEnumIfPresent(QuizType.self, forKey: .quizType)
        settings = try container.decodeIfPresent(QuizSettingsDTO.self, forKey: .settings)
        status = try container.decodeEnumIfPresent(QuizStatus.self, forKey: .status)
        templateId = try container.decodeIfPresent(String.self, forKey: .templateId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        totalQuestions = try container.decodeStringFromStringOrIntIfPresent(forKey: .totalQuestions)
        totalTime = try container.decodeStringFromStringOrIntIfPresent(forKey: .totalTime)
    }
}

// MARK: - Constants
private extension InstanceDTO {
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
private extension InstanceDTO {
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
