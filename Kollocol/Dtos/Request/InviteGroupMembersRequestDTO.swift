//
//  InviteGroupMembersRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct InviteGroupMembersRequestDTO: Encodable {
    let emails: [String]
}

// MARK: - InviteGroupMembersRequest -> InviteGroupMembersRequestDTO
extension InviteGroupMembersRequest {
    func toDto() -> InviteGroupMembersRequestDTO {
        return InviteGroupMembersRequestDTO(emails: self.emails)
    }
}
