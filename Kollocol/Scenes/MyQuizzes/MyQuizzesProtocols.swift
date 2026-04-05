//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol MyQuizzesInteractor {
    func fetchHostingQuizzes() async
    func fetchTemplates() async
    func joinQuiz(code: String) async
    func generateTemplate(prompt: String) async throws -> GeneratedTemplate
    func handleTemplateGenerationError(_ error: MLServiceError) async
    func handleQuizCardTap(_ quiz: QuizInstanceViewData) async
    func routeToCreateTemplateScreen() async
    func routeToCreateTemplateScreen(from generatedTemplate: GeneratedTemplate) async
    func routeToStartQuizScreen(templateId: String?) async
    func handleTemplateTap(templateId: String) async
    func handleQuizTypeTap(_ quizType: QuizType) async
    func handleTemplateSearchQueryChanged(_ query: String)
}

protocol MyQuizzesPresenter {
    func presentHostingQuizzes(_ hosting: [QuizInstance]) async
    func presentTemplates(_ templates: [QuizTemplate], emptyStateText: String?) async
    func presentServiceError(_ error: QuizServiceError) async
    func presentTemplateGenerationError(_ error: MLServiceError) async
    func presentCreateTemplateScreen() async
    func presentCreateTemplateScreen(from generatedTemplate: GeneratedTemplate) async
    func presentStartQuizScreen(template: QuizTemplate) async
    func presentTemplateEditingScreen(_ template: QuizTemplate) async
    func presentJoinQuizSuccess(accessCode: String) async
    func presentJoinQuizError(_ error: QuizParticipationServiceError) async
    func presentJoinQuizConfirmation(accessCode: String, quizTitle: String) async
    func presentQuizTypeInfo(_ quizType: QuizType) async
}
