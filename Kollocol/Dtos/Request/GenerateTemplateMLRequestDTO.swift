//
//  GenerateTemplateMLRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateMLRequestDTO: Encodable {
    let text: String
}

// MARK: - GenerateTemplateMLRequest -> GenerateTemplateMLRequestDTO
extension GenerateTemplateMLRequest {
    func toDto() -> GenerateTemplateMLRequestDTO {
        GenerateTemplateMLRequestDTO(text: text)
    }
}
