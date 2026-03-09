//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MyQuizzesLogic: MyQuizzesInteractor {
    // MARK: - Constants
    private let presenter: MyQuizzesPresenter
    private let quizService: QuizService

    // MARK: - Lifecycle
    init(presenter: MyQuizzesPresenter, quizService: QuizService) {
        self.presenter = presenter
        self.quizService = quizService
    }

    // MARK: - Methods
    func fetchHostingQuizzes() async {
        do {
            let hosting = try await quizService.getHostingQuizzes()
            await presenter.presentHostingQuizzes(hosting)
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func routeToCreateTemplateScreen() async {
        await presenter.presentCreateTemplateScreen()
    }

    func routeToStartQuizScreen(templateId: String?) async {
        await presenter.presentStartQuizScreen(templateId: templateId)
    }
}
