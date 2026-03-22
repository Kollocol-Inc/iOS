//
//  StartQuizModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

enum StartQuizModels {
    enum Row {
        case header(String)
        case nameInput
        case deadline
    }

    struct FormData {
        let title: String?
        let deadline: Date?
    }

    struct InitialData {
        let title: String
        let quizType: QuizType?
    }
}
