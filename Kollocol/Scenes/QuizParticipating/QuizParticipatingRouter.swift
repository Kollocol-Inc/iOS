//
//  QuizParticipatingRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

@MainActor
final class QuizParticipatingRouter: QuizParticipatingPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: QuizParticipatingViewController?

    private let router: QuizParticipatingRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: QuizParticipatingRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentQuizTitle(_ quizTitle: String) async {
        await view?.displayQuizTitle(quizTitle)
    }

    func presentState(_ state: QuizParticipatingModels.ViewState) async {
        await view?.displayState(state)
    }

    func presentServiceError(_ error: QuizParticipationServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentServerError(message: String) async {
        await router.showError(title: "Ошибка", message: message)
    }

    func presentKickedFromQuiz(quizTitle: String?) async {
        await router.showKickedFromQuizSheetAndClose(quizTitle: quizTitle)
    }

    func presentSessionReplaced() async {
        await router.showSessionReplacedSheetAndClose()
    }

    func presentQuizDeletedByCreator() async {
        await router.showQuizDeletedByCreatorSheetAndClose()
    }

    func presentQuizCanceled(quizTitle: String) async {
        await router.showQuizCanceledSheetAndClose(quizTitle: quizTitle)
    }

    func presentLeaveConfirmation() async {
        await router.showQuizLeaveConfirmation { [weak self] in
            self?.view?.confirmLeaveAfterAlert()
        }
    }

    func presentCloseFlow() async {
        await router.closeQuizParticipatingFlow()
    }
}

@MainActor
protocol QuizParticipatingRouting: ErrorMessageDisplaying {
    func closeQuizParticipatingFlow()
    func showQuizLeaveConfirmation(onConfirm: @escaping @MainActor () -> Void)
    func showKickedFromQuizSheetAndClose(quizTitle: String?)
    func showSessionReplacedSheetAndClose()
    func showQuizDeletedByCreatorSheetAndClose()
    func showQuizCanceledSheetAndClose(quizTitle: String)
}
