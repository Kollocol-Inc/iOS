//
//  RegisterResponse.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import Foundation

struct UserDTO: Decodable {
    // MARK: - Constants
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

    // MARK: - Properties
    let avatarUrl: String?
    let createdAt: Date?
    let email: String?
    let firstName: String?
    let id: String?
    let lastName: String?
    let updatedAt: Date?

    // MARK: - Methods
    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case email
        case firstName = "first_name"
        case id
        case lastName = "last_name"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        id = try container.decode(String.self, forKey: .id)
        lastName = try container.decode(String.self, forKey: .lastName)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = try Self.parseRFC3339(createdAtString, key: .createdAt)

        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        updatedAt = try Self.parseRFC3339(updatedAtString, key: .updatedAt)
    }

    // MARK: - Private Methods
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
