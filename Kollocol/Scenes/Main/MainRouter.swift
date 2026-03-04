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

    func presentUserServiceError(_ error: UserServiceError) async {
        await presentServiceError(error)
    }

    func presentQuizServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error)
    }

    func presentProfileScreen() async {
        await router.routeToProfileScreen()
    }

    func presentJoinQuizSuccess() async {
        // TODO: Handle success
    }

    func presentJoinQuizError() async {
        await router.showError(
            title: "Неверный код",
            message: "Такой код не существует или Вы ввели код неверно. Попробуйте еще раз"
        )
        await view?.resetCodeFields()
    }
}
