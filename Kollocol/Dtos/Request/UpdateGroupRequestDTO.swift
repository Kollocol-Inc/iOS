//
//  UpdateGroupRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct UpdateGroupRequestDTO: Encodable {
    let avatarUrl: String?
    let description: String?
    let name: String?

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
        case description
        case name
    }
}

// MARK: - UpdateGroupRequest -> UpdateGroupRequestDTO
extension UpdateGroupRequest {
    func toDto() -> UpdateGroupRequestDTO {
        return UpdateGroupRequestDTO(
            avatarUrl: self.avatarUrl,
            description: self.description,
            name: self.name
        )
    }
}
