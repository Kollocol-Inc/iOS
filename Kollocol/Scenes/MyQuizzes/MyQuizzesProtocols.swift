//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol MyQuizzesInteractor {
    func fetchHostingQuizzes() async
    func routeToCreateTemplateScreen() async
    func routeToStartQuizScreen(templateId: String?) async
}

protocol MyQuizzesPresenter {
    func presentHostingQuizzes(_ hosting: [QuizInstance]) async
    func presentServiceError(_ error: QuizServiceError) async
    func presentCreateTemplateScreen() async
    func presentStartQuizScreen(templateId: String?) async
}
