//
//  CreateTemplateRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

struct CreateTemplateRequestDTO: Encodable {
    let description: String?
    let questions: [QuestionInputDto]?
    let quizType: QuizType?
    let settings: QuizSettingsDTO?
    let title: String?

    private enum CodingKeys: String, CodingKey {
        case description
        case questions
        case quizType = "quiz_type"
        case settings
        case title
    }
}

// MARK: - Encodable
extension CreateTemplateRequestDTO {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(questions, forKey: .questions)
        try container.encodeEnumIfPresent(quizType, forKey: .quizType)
        try container.encodeIfPresent(settings, forKey: .settings)
        try container.encodeIfPresent(title, forKey: .title)
    }
}

// MARK: - CreateTemplateRequest -> CreateTemplateRequestDTO
extension CreateTemplateRequest {
    func toDto() -> CreateTemplateRequestDTO {
        return CreateTemplateRequestDTO(
            description: self.description,
            questions: self.questions?.map { $0.toDto() },
            quizType: self.quizType,
            settings: self.settings?.toDto(),
            title: self.title
        )
    }
}
