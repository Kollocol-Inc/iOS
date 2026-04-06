//
//  TemplateCreatingModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

enum TemplateCreatingModels {
    enum Row {
        case header(String)
        case nameInput
        case settings
        case divider
        case questionActions
        case questionsSummary
        case questionsSearch
        case question(index: Int, sourceIndex: Int, question: Question, isAIGenerated: Bool)
        case questionShimmer
    }

    struct FormData {
        let title: String?
        let quizType: QuizType
        let isRandomOrderEnabled: Bool
        let questions: [Question]
    }
}
