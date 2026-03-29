//
//  QuizWaitingRoomCoordinator.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

@MainActor
final class QuizWaitingRoomCoordinator {
    // MARK: - Properties
    private let navigationController: UINavigationController
    private let quizParticipationService: QuizParticipationService
    private let initialData: QuizWaitingRoomModels.InitialData
    private let onFinish: () -> Void

    private weak var entryViewController: UIViewController?

    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        quizParticipationService: QuizParticipationService,
        initialData: QuizWaitingRoomModels.InitialData,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.quizParticipationService = quizParticipationService
        self.initialData = initialData
        self.onFinish = onFinish
    }

    // MARK: - Methods
    func start() {
        entryViewController = navigationController.topViewController

        let viewController = QuizWaitingRoomAssembly.build(
            router: self,
            quizParticipationService: quizParticipationService,
            initialData: initialData
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }
}

// MARK: - AlertPresenting
extension QuizWaitingRoomCoordinator: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        navigationController.visibleViewController?.present(alert, animated: true)
    }
}

// MARK: - QuizWaitingRoomRouting
extension QuizWaitingRoomCoordinator: QuizWaitingRoomRouting {
    func closeQuizWaitingRoomFlow() {
        if let entryViewController {
            navigationController.popToViewController(entryViewController, animated: true)
        } else {
            navigationController.popToRootViewController(animated: true)
        }
        onFinish()
    }

    func routeToQuizParticipating() {
        let viewController = QuizParticipatingAssembly.build(
            router: self,
            quizParticipationService: quizParticipationService
        )
        viewController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(viewController, animated: true)
    }

    func showError(title: String, message: String) {
        showAlert(title: title, message: message)
    }
}

// MARK: - QuizParticipatingRouting
extension QuizWaitingRoomCoordinator: QuizParticipatingRouting {
    func closeQuizParticipatingFlow() {
        closeQuizWaitingRoomFlow()
    }

    func showQuizLeaveConfirmation(onConfirm: @escaping @MainActor () -> Void) {
        showConfirmationAlert(
            title: "Внимание",
            message: "Вы уверены, что хотите выйти? Вы сможете вернуться в любой момент",
            cancelTitle: "Отмена",
            confirmTitle: "Выйти",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
}

@MainActor
protocol QuizWaitingRoomRouting: ErrorMessageDisplaying {
    func closeQuizWaitingRoomFlow()
    func routeToQuizParticipating()
    func showQuizLeaveConfirmation(onConfirm: @escaping @MainActor () -> Void)
}
