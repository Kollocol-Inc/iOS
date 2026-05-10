//
//  NotificationIDsRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct NotificationIDsRequestDTO: Encodable {
    let ids: [String]
}

// MARK: - NotificationIDsRequest -> NotificationIDsRequestDTO
extension NotificationIDsRequest {
    func toDto() -> NotificationIDsRequestDTO {
        return NotificationIDsRequestDTO(ids: self.ids)
    }
}
