//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MainRouter: MainPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: MainViewController?
    
    private let router: MainRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }
    
    // MARK: - Lifecycle
    init(router: MainRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentUserProfile(_ user: UserDTO) async {
        let name = [user.firstName, user.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        await view?.displayUserProfile(avatarUrl: user.avatarUrl, name: name)
    }

    func presentQuizzes(participating: [QuizInstance], hosting: [QuizInstance]) async {
        let participatingViewData = participating.map { $0.toViewData() }
        let hostingViewData = hosting.map { $0.toViewData() }
        await view?.displayQuizzes(participating: participatingViewData, hosting: hostingViewData)
    }

    func presentServiceError(_ error: any UserFacingError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentProfileScreen() async {
        await router.routeToProfileScreen()
    }

    func presentJoinQuizSuccess() async {
        // TODO: Handle success
    }

    func presentJoinQuizError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .joinQuiz, title: "Неверный код")
        await view?.resetCodeFields()
    }

    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        guard let quizServiceError = error as? QuizServiceError else { return nil }

        switch useCase {
        case .joinQuiz:
            if quizServiceError == .badRequest {
                return "Такой код не существует или Вы ввели код неверно. Попробуйте еще раз"
            }
            return nil

        default:
            return nil
        }
    }
}
