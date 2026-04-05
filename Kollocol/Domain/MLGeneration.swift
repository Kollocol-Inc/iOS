//
//  MLGeneration.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateMLRequest {
    let text: String
}

struct GenerateTemplateQuestionsMLRequest {
    let text: String?
    let questions: [Question]?
}

struct ParaphraseMLRequest {
    let text: String
}

struct GeneratedTemplate {
    let title: String?
    let questions: [Question]
}

struct GeneratedQuestions {
    let questions: [Question]
}

struct ParaphrasedText {
    let text: String?
}
