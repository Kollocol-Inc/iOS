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
    private let quizParticipationService: QuizParticipationService

    // MARK: - Properties
    var participatingInstances: [ParticipatingInstance] = []
    var hostingInstances: [QuizInstance] = []

    // MARK: - Lifecycle
    init(
        presenter: MainPresenter,
        userService: UserService,
        quizService: QuizService,
        quizParticipationService: QuizParticipationService
    ) {
        self.presenter = presenter
        self.userService = userService
        self.quizService = quizService
        self.quizParticipationService = quizParticipationService
    }

    // MARK: - Methods
    func fetchUserProfile() async {
        do {
            let user = try await userService.getUserProfile()
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentServiceError(UserServiceError.wrap(error))
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
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func routeToProfileScreen() async {
        await presenter.presentProfileScreen()
    }

    func joinQuiz(code: String, skipAsyncConfirmation: Bool) async {
        do {
            try await quizParticipationService.connect(accessCode: code)

            let connectedPayload = await quizParticipationService.currentConnectedPayload()
            let shouldPresentAsyncStartConfirmation = skipAsyncConfirmation == false
                && connectedPayload?.quizType == .async
                && connectedPayload?.isCreator == false

            if shouldPresentAsyncStartConfirmation {
                let quizTitle = await quizParticipationService.currentQuizTitle()
                await quizParticipationService.disconnect()
                await presenter.presentAsyncQuizStartConfirmation(
                    accessCode: code,
                    quizTitle: quizTitle
                )
                return
            }

            await presenter.presentJoinQuizSuccess(accessCode: code)
        } catch {
            await presenter.presentJoinQuizError(QuizParticipationServiceError.wrap(error))
        }
    }

    func handleQuizCardTap(_ quiz: QuizInstanceViewData) async {
        let accessCode = quiz.accessCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard accessCode.isEmpty == false else {
            return
        }

        let normalizedTitle = normalizedString(quiz.title)
        let isHostingQuiz = isHostingQuiz(quiz)
        let shouldShowAsyncStartConfirmation = quiz.quizType == .async && isHostingQuiz == false

        if shouldShowAsyncStartConfirmation {
            await presenter.presentAsyncQuizStartConfirmation(
                accessCode: accessCode,
                quizTitle: normalizedTitle.isEmpty ? nil : normalizedTitle
            )
            return
        }

        await presenter.presentJoinQuizConfirmation(
            accessCode: accessCode,
            quizTitle: normalizedTitle
        )
    }

    func handleQuizTypeTap(_ quizType: QuizType) async {
        await presenter.presentQuizTypeInfo(quizType)
    }

    // MARK: - Private Methods
    private func isHostingQuiz(_ quiz: QuizInstanceViewData) -> Bool {
        let targetQuizID = normalizedString(quiz.id)
        let targetAccessCode = normalizedString(quiz.accessCode)

        return hostingInstances.contains { instance in
            let instanceQuizID = normalizedString(instance.id)
            if targetQuizID.isEmpty == false,
               instanceQuizID.isEmpty == false,
               targetQuizID == instanceQuizID {
                return true
            }

            let instanceAccessCode = normalizedString(instance.accessCode)
            if targetAccessCode.isEmpty == false,
               instanceAccessCode.isEmpty == false,
               targetAccessCode == instanceAccessCode {
                return true
            }

            return false
        }
    }

    private func normalizedString(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
