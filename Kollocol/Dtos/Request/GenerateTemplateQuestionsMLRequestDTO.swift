//
//  GenerateTemplateQuestionsMLRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateQuestionsMLRequestDTO: Encodable {
    let text: String?
    let questions: [QuestionInputDto]?
}

// MARK: - GenerateTemplateQuestionsMLRequest -> GenerateTemplateQuestionsMLRequestDTO
extension GenerateTemplateQuestionsMLRequest {
    func toDto() -> GenerateTemplateQuestionsMLRequestDTO {
        GenerateTemplateQuestionsMLRequestDTO(
            text: text,
            questions: questions?.map { $0.toDto() }
        )
    }
}
