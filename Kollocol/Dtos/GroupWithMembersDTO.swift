//
//  GroupWithMembersDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GroupWithMembersDTO: Decodable {
    let avatarUrl: String?
    let createdAt: Date?
    let description: String?
    let id: String?
    let invitedUsers: [GroupMemberDTO]?
    let memberCount: Int?
    let members: [GroupMemberDTO]?
    let name: String?
    let ownerId: String?
    let pendingInvitesCount: Int?
    let updatedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case description
        case id
        case invitedUsers = "invited_users"
        case memberCount = "member_count"
        case members
        case name
        case ownerId = "owner_id"
        case pendingInvitesCount = "pending_invites_count"
        case pendingCount = "pending_count"
        case updatedAt = "updated_at"
    }
}

// MARK: - GroupWithMembersDTO -> GroupWithMembers
extension GroupWithMembersDTO {
    func toDomain() -> GroupWithMembers {
        return GroupWithMembers(
            avatarUrl: self.avatarUrl,
            createdAt: self.createdAt,
            description: self.description,
            id: self.id,
            invitedUsers: self.invitedUsers?.map { $0.toDomain() } ?? [],
            memberCount: self.memberCount,
            members: self.members?.map { $0.toDomain() } ?? [],
            name: self.name,
            ownerId: self.ownerId,
            pendingInvitesCount: self.pendingInvitesCount,
            updatedAt: self.updatedAt
        )
    }
}

// MARK: - Decodable
extension GroupWithMembersDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)

        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)
        } else {
            createdAt = nil
        }

        description = try container.decodeIfPresent(String.self, forKey: .description)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        invitedUsers = try container.decodeIfPresent([GroupMemberDTO].self, forKey: .invitedUsers)
        memberCount = try container.decodeIfPresent(Int.self, forKey: .memberCount)
        members = try container.decodeIfPresent([GroupMemberDTO].self, forKey: .members)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        ownerId = try container.decodeIfPresent(String.self, forKey: .ownerId)
        pendingInvitesCount = try container.decodeIfPresent(Int.self, forKey: .pendingInvitesCount)
            ?? container.decodeIfPresent(Int.self, forKey: .pendingCount)

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = try Self.parseRFC3339(updatedAtString, key: .updatedAt)
        } else {
            updatedAt = nil
        }
    }
}

// MARK: - Constants
private extension GroupWithMembersDTO {
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
private extension GroupWithMembersDTO {
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
