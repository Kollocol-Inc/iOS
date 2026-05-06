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
        case group
    }

    struct GroupOption {
        let id: String
        let title: String
    }

    struct FormData {
        let groupId: String?
        let title: String?
        let deadline: Date?
    }

    struct InitialData {
        let groupId: String?
        let title: String
        let quizType: QuizType?
    }
}
