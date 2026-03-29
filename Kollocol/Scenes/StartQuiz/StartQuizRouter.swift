//
//  StartQuizRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

@MainActor
final class StartQuizRouter: StartQuizPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: StartQuizViewController?

    private let router: StartQuizRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: StartQuizRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentStartQuizLoading(_ isLoading: Bool) async {
        await view?.displayStartQuizLoading(isLoading)
    }

    func presentStartQuizSuccess() async {
        await router.dismissStartQuizScreen()
    }

    func presentStartSyncQuizSuccess(accessCode: String) async {
        await router.routeToQuizWaitingRoomFromStartQuiz(accessCode: accessCode)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        await presentServiceError(error, useCase: .joinQuiz)
    }

    func presentCloseScreen() async {
        await router.dismissStartQuizScreen()
    }
}
