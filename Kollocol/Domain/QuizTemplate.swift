//
//  QuizTemplate.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct QuizTemplate {
    let createdAt: Date?
    let description: String?
    let id: String?
    let questions: [Question]?
    let quizType: QuizType?
    let settings: QuizSettings?
    let title: String?
    let updatedAt: Date?
    let userId: String?
}

// MARK: - QuizTemplate -> QuizInstanceViewData
extension QuizTemplate {
    func toViewData() -> QuizInstanceViewData {
        let questionsCount = questions?.count
        let totalQuestionsText: String? = {
            guard let questionsCount else { return nil }
            return "\(questionsCount)"
        }()

        return QuizInstanceViewData(
            accessCode: nil,
            deadline: nil,
            id: id,
            quizType: quizType,
            status: nil,
            title: title,
            totalQuestions: totalQuestionsText,
            totalTime: nil
        )
    }
}
