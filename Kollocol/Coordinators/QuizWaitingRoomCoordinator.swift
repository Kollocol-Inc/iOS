//
//  QuizWaitingRoomCoordinator.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

@MainActor
final class QuizWaitingRoomCoordinator {
    // MARK: - Types
    enum StartDestination {
        case waitingRoom
        case participating
    }

    // MARK: - Properties
    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let navigationController: UINavigationController
    private let quizParticipationService: QuizParticipationService
    private let initialData: QuizWaitingRoomModels.InitialData
    private let startDestination: StartDestination
    private let onFinish: () -> Void

    private weak var entryViewController: UIViewController?

    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        quizParticipationService: QuizParticipationService,
        initialData: QuizWaitingRoomModels.InitialData,
        startDestination: StartDestination = .waitingRoom,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.quizParticipationService = quizParticipationService
        self.initialData = initialData
        self.startDestination = startDestination
        self.onFinish = onFinish
    }

    // MARK: - Methods
    func start() {
        entryViewController = navigationController.topViewController
        logQuizFlow(
            "start called. destination=\(startDestination.logDescription), " +
            "entryViewController=\(String(describing: type(of: entryViewController)))"
        )

        switch startDestination {
        case .waitingRoom:
            let viewController = QuizWaitingRoomAssembly.build(
                router: self,
                quizParticipationService: quizParticipationService,
                initialData: initialData
            )
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            logQuizFlow("waiting room screen pushed")

        case .participating:
            let viewController = QuizParticipatingAssembly.build(
                router: self,
                quizParticipationService: quizParticipationService
            )
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            logQuizFlow("participating screen pushed directly")
        }
    }

    private func logQuizFlow(_ message: String) {
        #if DEBUG
        let timestamp = Self.logDateFormatter.string(from: Date())
        print("[QuizFlow][QuizWaitingRoomCoordinator][\(timestamp)] \(message)")
        #endif
    }

    private func popToEntryViewController(animated: Bool) {
        if let entryViewController {
            navigationController.popToViewController(entryViewController, animated: animated)
        } else {
            navigationController.popToRootViewController(animated: animated)
        }
    }
}

// MARK: - AlertPresenting
extension QuizWaitingRoomCoordinator: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        navigationController.visibleViewController?.present(alert, animated: true)
    }
}

// MARK: - InfoBottomSheetPresenting
extension QuizWaitingRoomCoordinator: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        navigationController.visibleViewController
            ?? navigationController.topViewController
            ?? navigationController
    }
}

// MARK: - QuizWaitingRoomRouting
extension QuizWaitingRoomCoordinator: QuizWaitingRoomRouting {
    func closeQuizWaitingRoomFlow() {
        logQuizFlow("closeQuizWaitingRoomFlow called")
        popToEntryViewController(animated: true)
        onFinish()
    }

    func routeToQuizParticipating() {
        logQuizFlow("routeToQuizParticipating called from waiting room")
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

    func showKickParticipantConfirmation(
        participantName: String,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        showKickParticipantConfirmationSheet(participantName: participantName, onConfirm: onConfirm)
    }

    func showKickedFromQuizSheetAndClose(quizTitle: String?) {
        logQuizFlow("showKickedFromQuizSheetAndClose called")

        let showSheet: () -> Void = { [weak self] in
            guard let self else { return }
            self.showKickedFromQuizSheet(quizTitle: quizTitle)
            self.onFinish()
        }

        popToEntryViewController(animated: true)

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                showSheet()
            }
            return
        }

        DispatchQueue.main.async {
            showSheet()
        }
    }

    func showSessionReplacedSheetAndClose() {
        logQuizFlow("showSessionReplacedSheetAndClose called")

        let showSheet: () -> Void = { [weak self] in
            guard let self else { return }
            self.showSessionReplacedSheet()
            self.onFinish()
        }

        popToEntryViewController(animated: true)

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { _ in
                showSheet()
            }
            return
        }

        DispatchQueue.main.async {
            showSheet()
        }
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
    func showKickParticipantConfirmation(
        participantName: String,
        onConfirm: @escaping @MainActor () -> Void
    )
    func showKickedFromQuizSheetAndClose(quizTitle: String?)
    func showSessionReplacedSheetAndClose()
}

// MARK: - Private Methods
private extension QuizWaitingRoomCoordinator.StartDestination {
    var logDescription: String {
        switch self {
        case .waitingRoom:
            return "waitingRoom"
        case .participating:
            return "participating"
        }
    }
}
