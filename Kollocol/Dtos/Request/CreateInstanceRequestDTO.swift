//
//  CreateInstanceRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

struct CreateInstanceRequestDTO: Encodable {
    let deadline: String?
    let groupId: String?
    let templateId: String?
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case deadline
        case groupId = "group_id"
        case templateId = "template_id"
        case title
    }
}

// MARK: - CreateInstanceRequest -> CreateInstanceRequestDTO
extension CreateInstanceRequest {
    func toDto() -> CreateInstanceRequestDTO {
        return CreateInstanceRequestDTO(
            deadline: self.deadline?.asRFC3339String(),
            groupId: self.groupId,
            templateId: self.templateId,
            title: self.title
        )
    }
}
