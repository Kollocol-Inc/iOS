//
//  QuizWaitingRoomRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

@MainActor
final class QuizWaitingRoomRouter: QuizWaitingRoomPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: QuizWaitingRoomViewController?

    private let router: QuizWaitingRoomRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: QuizWaitingRoomRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentIsCreator(_ isCreator: Bool) async {
        await view?.displayIsCreator(isCreator)
    }

    func presentCurrentUserID(_ userID: String?) async {
        await view?.displayCurrentUserID(userID)
    }

    func presentQuizTitle(_ quizTitle: String) async {
        await view?.displayQuizTitle(quizTitle)
    }

    func presentParticipantsCount(_ count: Int) async {
        await view?.displayParticipantsCount(count)
    }

    func presentParticipants(_ participants: [QuizParticipant]) async {
        await view?.displayParticipants(participants)
    }

    func presentRouteToQuizParticipating() async {
        await router.routeToQuizParticipating()
    }

    func presentServiceError(_ error: QuizParticipationServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentServerError(message: String) async {
        await router.showError(title: "Ошибка", message: message)
    }

    func presentLeaveConfirmation() async {
        await router.showQuizLeaveConfirmation { [weak self] in
            self?.view?.confirmLeaveAfterAlert()
        }
    }

    func presentCloseFlow() async {
        await router.closeQuizWaitingRoomFlow()
    }
}
