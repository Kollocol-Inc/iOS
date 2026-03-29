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

    func presentJoinQuizSuccess(accessCode: String) async {
        await view?.resetCodeFields()
        await router.routeToQuizWaitingRoom(accessCode: accessCode)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        let title = error == .invalidCode ? "Неверный код" : "Ошибка"
        await presentServiceError(error, useCase: .joinQuiz, title: title)
        await view?.resetCodeFields()
    }

    func presentQuizTypeInfo(_ quizType: QuizType) async {
        await router.showQuizTypeInfoBottomSheet(
            title: quizType.displayName,
            description: quizType.infoDescription
        )
    }

    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        switch useCase {
        case .joinQuiz:
            if let quizParticipationError = error as? QuizParticipationServiceError,
               quizParticipationError == .invalidCode {
                return "Такой код не существует или Вы ввели код неверно. Попробуйте еще раз"
            }
            return nil

        default:
            return nil
        }
    }
}
