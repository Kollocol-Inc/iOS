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
    var hostingInstances: [QuizInstance] = []

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
            await presenter.presentUserServiceError(UserServiceError.wrap(error))
        }
    }

    func fetchQuizzes() async {
        do {
            async let participatingTask = quizService.getParticipatingQuizzes()
            async let hostingTask = quizService.getHostingQuizzes()

            let (participatingInstances, hostingInstances) = try await (participatingTask, hostingTask)
            self.participatingInstances = participatingInstances
            self.hostingInstances = hostingInstances
            await presenter.presentQuizzes(
                participating: participatingInstances.compactMap { $0.instance },
                hosting: hostingInstances
            )
        } catch {
            await presenter.presentQuizServiceError(QuizServiceError.wrap(error))
        }
    }

    func routeToProfileScreen() async {
        await presenter.presentProfileScreen()
    }

    func joinQuiz(code: String) async {
        await presenter.presentJoinQuizError()
    }
}
