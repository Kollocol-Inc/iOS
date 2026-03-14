//
//  CreateTemplateRequest.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

struct CreateTemplateRequest {
    let description: String?
    let questions: [Question]?
    let quizType: QuizType?
    let settings: QuizSettings?
    let title: String?
}
