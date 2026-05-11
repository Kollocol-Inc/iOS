//
//  UserNotificationDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct UserNotificationDTO: Decodable {
    let content: String?
    let createdAt: Date?
    let id: String?
    let isRead: Bool?
    let relatedEntityId: String?
    let requiresAction: Bool?
    let title: String?
    let type: String?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case content
        case createdAt = "created_at"
        case groupId = "group_id"
        case id
        case isRead = "is_read"
        case relatedEntityId = "related_entity_id"
        case requiresAction = "requires_action"
        case title
        case type
        case userId = "user_id"
    }
}

// MARK: - UserNotificationDTO -> UserNotification
extension UserNotificationDTO {
    func toDomain() -> UserNotification {
        return UserNotification(
            content: self.content,
            createdAt: self.createdAt,
            id: self.id,
            isRead: self.isRead,
            relatedEntityId: self.relatedEntityId,
            requiresAction: self.requiresAction,
            title: self.title,
            type: Self.mapType(self.type),
            userId: self.userId
        )
    }
}

// MARK: - Decodable
extension UserNotificationDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)
        } else {
            createdAt = nil
        }

        content = try container.decodeIfPresent(String.self, forKey: .content)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead)
        relatedEntityId = try container.decodeIfPresent(String.self, forKey: .relatedEntityId)
            ?? (try container.decodeIfPresent(String.self, forKey: .groupId))
        requiresAction = try container.decodeIfPresent(Bool.self, forKey: .requiresAction)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}

// MARK: - Constants
private extension UserNotificationDTO {
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
private extension UserNotificationDTO {
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

    private static func mapType(_ rawValue: String?) -> UserNotificationType {
        guard let rawValue else { return .unknown }
        return UserNotificationType(rawValue: rawValue) ?? .unknown
    }
}
