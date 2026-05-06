//
//  GroupMemberDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GroupMemberDTO: Decodable {
    let avatarUrl: String?
    let email: String?
    let firstName: String?
    let joinedAt: Date?
    let lastName: String?
    let userId: String?

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case email
        case firstName = "first_name"
        case joinedAt = "joined_at"
        case lastName = "last_name"
        case userId = "user_id"
    }
}

// MARK: - GroupMemberDTO -> GroupMember
extension GroupMemberDTO {
    func toDomain() -> GroupMember {
        return GroupMember(
            avatarUrl: self.avatarUrl,
            email: self.email,
            firstName: self.firstName,
            joinedAt: self.joinedAt,
            lastName: self.lastName,
            userId: self.userId
        )
    }
}

// MARK: - Decodable
extension GroupMemberDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)

        if let joinedAtString = try container.decodeIfPresent(String.self, forKey: .joinedAt) {
            joinedAt = try Self.parseRFC3339(joinedAtString, key: .joinedAt)
        } else {
            joinedAt = nil
        }

        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
}

// MARK: - Constants
private extension GroupMemberDTO {
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
private extension GroupMemberDTO {
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

