//
//  QuizInstance.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct QuizInstance {
    let accessCode:     String?
    let createdAt:      Date?
    let deadline:       String?
    let groupId:        String?
    let hostUserId:     String?
    let id:             String?
    let quizType:       QuizType?
    let settings:       QuizSettings?
    let status:         QuizStatus?
    let templateId:     String?
    let title:          String?
    let totalQuestions: String?
    let totalTime:      String?
}

// MARK: - QuizInstance -> QuizInstanceViewData
extension QuizInstance {
    func toViewData() -> QuizInstanceViewData {
        return QuizInstanceViewData(
            accessCode: self.accessCode,
            deadline: self.deadline,
            id: self.id,
            quizType: self.quizType,
            status: self.status,
            title: self.title,
            totalQuestions: self.totalTime,
            totalTime: self.totalTime?.asHmsFromSeconds()
        )
    }
}
