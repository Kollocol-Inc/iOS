//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MyQuizzesRouter: MyQuizzesPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: MyQuizzesViewController?

    private let router: MyQuizzesRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: MyQuizzesRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentHostingQuizzes(_ hosting: [QuizInstance]) async {
        let items = hosting.map { $0.toViewData() }
        await view?.displayHostingQuizzes(items)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentCreateTemplateScreen() async {
        await router.routeToCreateTemplateScreen()
    }
}
