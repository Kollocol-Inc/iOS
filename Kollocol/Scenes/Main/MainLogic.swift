//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MainLogic: MainInteractor {
    // MARK: - Constants
    private let presenter: MainPresenter
    private let userService: UserService
    private let quizService: QuizService

    // MARK: - Properties
    var participatingInstances: [ParticipatingInstance] = []

    // MARK: - Lifecycle
    init(presenter: MainPresenter, userService: UserService, quizService: QuizService) {
        self.presenter = presenter
        self.userService = userService
        self.quizService = quizService
    }

    // MARK: - Methods
    func fetchUserProfile() async {
        do {
            let user = try await userService.getUserProfile()
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentError(UserServiceError.wrap(error))
        }
    }

    func fetchParticipatingQuizzes() async {
        do {
            let participatingInstances = try await quizService.getParticipatingQuizzes()
            self.participatingInstances = participatingInstances
            await presenter.presentParticipatingQuizzes(participatingInstances.compactMap { $0.instance })
        } catch {
            await presenter.presentError(UserServiceError.wrap(error))
        }
    }

    func routeToProfileScreen() async {
        await presenter.presentProfileScreen()
    }

    func joinQuiz(code: String) async {
        await presenter.presentJoinQuizError()
    }
}
