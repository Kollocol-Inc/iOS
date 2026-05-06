//
//  CreateGroupRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct CreateGroupRequestDTO: Encodable {
    let avatarUrl: String?
    let description: String?
    let memberEmails: [String]?
    let name: String

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case description
        case memberEmails = "member_emails"
        case name
    }
}

// MARK: - CreateGroupRequest -> CreateGroupRequestDTO
extension CreateGroupRequest {
    func toDto() -> CreateGroupRequestDTO {
        return CreateGroupRequestDTO(
            avatarUrl: self.avatarUrl,
            description: self.description,
            memberEmails: self.memberEmails,
            name: self.name
        )
    }
}
