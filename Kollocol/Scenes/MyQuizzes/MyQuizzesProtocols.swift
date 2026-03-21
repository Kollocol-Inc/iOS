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
    func routeToCreateTemplateScreen() async
    func routeToStartQuizScreen(templateId: String?) async
    func handleTemplateTap(templateId: String) async
    func handleQuizTypeTap(_ quizType: QuizType) async
    func handleTemplateSearchQueryChanged(_ query: String)
}

protocol MyQuizzesPresenter {
    func presentHostingQuizzes(_ hosting: [QuizInstance]) async
    func presentTemplates(_ templates: [QuizTemplate], emptyStateText: String?) async
    func presentServiceError(_ error: QuizServiceError) async
    func presentCreateTemplateScreen() async
    func presentStartQuizScreen(templateId: String?) async
    func presentTemplateEditingScreen(_ template: QuizTemplate) async
    func presentQuizTypeInfo(_ quizType: QuizType) async
}
