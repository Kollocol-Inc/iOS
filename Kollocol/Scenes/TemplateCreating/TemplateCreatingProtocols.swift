//
//  TemplateCreatingProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

protocol TemplateCreatingInteractor: Actor {
    func createTemplate(formData: TemplateCreatingModels.FormData) async
    func handleQuizTypeInfoTap(_ quizType: QuizType) async
}

protocol TemplateCreatingPresenter {
    func presentCreateTemplateLoading(_ isLoading: Bool) async
    func presentCreateTemplateSuccess() async
    func presentServiceError(_ error: QuizServiceError) async
    func presentQuizTypeInfo(_ quizType: QuizType) async
}
