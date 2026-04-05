//
//  GeneratedTemplateDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GeneratedTemplateDTO: Decodable {
    let questions: [GeneratedQuestionDTO]?
    let title: String?
}

// MARK: - GeneratedTemplateDTO -> GeneratedTemplate
extension GeneratedTemplateDTO {
    func toDomain() -> GeneratedTemplate {
        GeneratedTemplate(
            title: title,
            questions: questions?.map { $0.toDomain() } ?? []
        )
    }
}
