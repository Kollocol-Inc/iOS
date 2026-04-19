//
//  QuizParticipantReviewRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

@MainActor
final class QuizParticipantReviewRouter: QuizParticipantReviewPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: QuizParticipantReviewViewController?

    private let router: QuizParticipantReviewRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: QuizParticipantReviewRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentViewData(_ viewData: QuizParticipantReviewModels.ViewData) async {
        await view?.displayViewData(viewData)
    }

    func presentCompletionInfo(pendingOpenQuestionsCount: Int) async {
        await view?.displayCompletionInfo(pendingOpenQuestionsCount: pendingOpenQuestionsCount)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }
}
