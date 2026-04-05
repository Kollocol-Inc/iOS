//
//  MainModels.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum MyQuizzesModels {
    enum MyQuizzesSection: Equatable {
        case active
        case pendingReview
        case reviewed
    }

    enum Mode {
        case myQuizzes
        case templates
    }

    enum Row {
        case header(title: String)
        case cards(items: [QuizInstanceViewData], section: MyQuizzesSection)
        case empty(text: String)
        case divider
    }
}
