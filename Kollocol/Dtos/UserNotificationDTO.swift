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
    let groupId: String?
    let id: String?
    let isRead: Bool?
    let title: String?
    let type: String?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case content
        case createdAt = "created_at"
        case groupId = "group_id"
        case id
        case isRead = "is_read"
        case title
        case type
        case userId = "user_id"
    }

    private enum AlternateCodingKeys: String, CodingKey {
        case groupIdCamel = "groupId"
        case groupID = "groupID"
        case group = "group"
        case entityId = "entity_id"
        case entityIdCamel = "entityId"
        case targetId = "target_id"
        case targetIdCamel = "targetId"
        case resourceId = "resource_id"
        case resourceIdCamel = "resourceId"
    }
}

// MARK: - UserNotificationDTO -> UserNotification
extension UserNotificationDTO {
    func toDomain() -> UserNotification {
        return UserNotification(
            content: self.content,
            createdAt: self.createdAt,
            groupId: self.groupId,
            id: self.id,
            isRead: self.isRead,
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
        let alternateContainer = try decoder.container(keyedBy: AlternateCodingKeys.self)

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)
        } else {
            createdAt = nil
        }

        let decodedContent = try container.decodeIfPresent(String.self, forKey: .content)
        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        let decodedType = try container.decodeIfPresent(String.self, forKey: .type)
        let primaryGroupId = try container.decodeIfPresent(String.self, forKey: .groupId)
        let alternateGroupId = try Self.decodeAlternateGroupId(from: alternateContainer)
        let fallbackGroupId = Self.extractGroupIdFallback(
            typeRawValue: decodedType,
            content: decodedContent,
            title: decodedTitle
        )

        content = decodedContent
        groupId = Self.normalizedNonEmpty(primaryGroupId ?? alternateGroupId ?? fallbackGroupId)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead)
        title = decodedTitle
        type = decodedType
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

        static let uuidPattern = #"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}"#
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

    private static func decodeAlternateGroupId(
        from container: KeyedDecodingContainer<AlternateCodingKeys>
    ) throws -> String? {
        if let value = try container.decodeIfPresent(String.self, forKey: .groupIdCamel) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .groupID) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .group) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .entityId) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .entityIdCamel) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .targetId) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .targetIdCamel) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .resourceId) { return value }
        if let value = try container.decodeIfPresent(String.self, forKey: .resourceIdCamel) { return value }
        return nil
    }

    private static func extractGroupIdFallback(
        typeRawValue: String?,
        content: String?,
        title: String?
    ) -> String? {
        guard mapType(typeRawValue) == .groupInvite else { return nil }
        return firstUUID(in: content) ?? firstUUID(in: title)
    }

    private static func firstUUID(in value: String?) -> String? {
        guard let value else { return nil }
        guard let range = value.range(of: Constants.uuidPattern, options: .regularExpression) else { return nil }
        return String(value[range])
    }

    private static func normalizedNonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedValue.isEmpty == false else { return nil }
        return trimmedValue
    }
}
