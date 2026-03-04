//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MainRouter: MainPresenter {
    // MARK: - Properties
    weak var view: MainViewController?
    
    private let router: MainRouting
    
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

    func presentError(_ error: UserServiceError) async {
        let message: String

        switch error {
            case .offline:
                message = "Нет интернета"
            default:
                message = "Что-то пошло не так"
        }

        await router.showError(title: "Ошибка", message: message)
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
