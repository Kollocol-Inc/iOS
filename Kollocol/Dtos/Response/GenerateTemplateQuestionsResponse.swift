//
//  GenerateTemplateQuestionsResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateQuestionsResponse: Decodable {
    let questions: [GeneratedQuestionDTO]
}

// MARK: - GenerateTemplateQuestionsResponse -> GeneratedQuestions
extension GenerateTemplateQuestionsResponse {
    func toDomain() -> GeneratedQuestions {
        GeneratedQuestions(
            questions: questions.map { $0.toDomain() }
        )
    }
}
