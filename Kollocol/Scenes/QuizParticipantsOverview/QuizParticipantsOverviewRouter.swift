//
//  QuizParticipantsOverviewRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

@MainActor
final class QuizParticipantsOverviewRouter: QuizParticipantsOverviewPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: QuizParticipantsOverviewViewController?

    private let router: QuizParticipantsOverviewRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: QuizParticipantsOverviewRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentParticipants(_ participants: [QuizInstanceParticipant]) async {
        await view?.displayParticipants(participants)
    }

    func presentPublishQuizResultsSuccess() async {
        await view?.displayQuizResultsPublished()
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }
}
