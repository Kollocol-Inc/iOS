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
            quizType: self.quizType?.displayName,
            title: self.title,
            totalQuestions: self.totalTime,
            totalTime: self.totalTime?.asHmsFromSeconds()
        )
    }
}

private extension String {
    /// Интерпретирует строку как секунды и возвращает "ч./м./с." формат.
    /// Примеры:
    /// "180" -> "3 м."
    /// "200" -> "3 м. 20 с."
    /// "45"  -> "45 с."
    /// "10000" -> "2 ч. 46 м. 40 с."
    func asHmsFromSeconds() -> String? {
        guard let totalSeconds = Int(self.trimmingCharacters(in: .whitespacesAndNewlines)),
              totalSeconds >= 0
        else { return nil }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours) ч.")
        }

        if minutes > 0 || hours > 0 {
            if minutes > 0 {
                parts.append("\(minutes) м.")
            } else if hours > 0 && seconds > 0 {
                parts.append("0 м.")
            }
        }

        if seconds > 0 || parts.isEmpty {
            parts.append("\(seconds) с.")
        }

        return parts.joined(separator: " ")
    }
}
