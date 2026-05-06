//
//  KickGroupMembersRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct KickGroupMembersRequestDTO: Encodable {
    let emails: [String]
}

// MARK: - KickGroupMembersRequest -> KickGroupMembersRequestDTO
extension KickGroupMembersRequest {
    func toDto() -> KickGroupMembersRequestDTO {
        return KickGroupMembersRequestDTO(emails: self.emails)
    }
}
