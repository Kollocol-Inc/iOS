//
//  Question.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct Question {
    let aiAnswer: String?
    let correctAnswer: String?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let orderIndex: Int?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?
}
