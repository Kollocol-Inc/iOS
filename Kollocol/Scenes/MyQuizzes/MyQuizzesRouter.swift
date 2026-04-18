//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MyQuizzesRouter: MyQuizzesPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: MyQuizzesViewController?

    private let router: MyQuizzesRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: MyQuizzesRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentHostingQuizzes(_ hosting: [QuizInstance]) async {
        let items = hosting.map { $0.toViewData() }
        await view?.displayHostingQuizzes(items)
    }

    func presentTemplates(_ templates: [QuizTemplate], emptyStateText: String?) async {
        let items = templates.map { $0.toViewData() }
        await view?.displayTemplates(items, emptyStateText: emptyStateText)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentTemplateGenerationError(_ error: MLServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentCreateTemplateScreen() async {
        await router.routeToCreateTemplateScreen()
    }

    func presentCreateTemplateScreen(from generatedTemplate: GeneratedTemplate) async {
        await router.routeToCreateTemplateScreen(
            prefilledTitle: generatedTemplate.title,
            questions: generatedTemplate.questions
        )
    }

    func presentQuizParticipantsOverview(_ initialData: QuizParticipantsOverviewModels.InitialData) async {
        await router.routeToQuizParticipantsOverviewFromMyQuizzes(initialData: initialData)
    }

    func presentStartQuizScreen(template: QuizTemplate) async {
        await router.routeToStartQuizScreen(template: template)
    }

    func presentTemplateEditingScreen(_ template: QuizTemplate) async {
        await router.routeToEditTemplateScreen(template: template)
    }

    func presentJoinQuizSuccess(accessCode: String) async {
        await router.routeToQuizWaitingRoomFromMyQuizzes(accessCode: accessCode)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        if error == .quizAlreadyFinished {
            await router.showQuizConnectionUnavailableBottomSheet(
                description: "Квиз уже завершен, подключение невозможно"
            )
            return
        }

        let title = error == .invalidCode ? "Неверный код" : "Ошибка"
        await presentServiceError(error, useCase: .joinQuiz, title: title)
    }

    func presentJoinQuizConfirmation(accessCode: String, quizTitle: String) async {
        await router.showQuizJoinConfirmationBottomSheet(quizTitle: quizTitle) { [weak self] in
            self?.view?.confirmJoinQuiz(accessCode: accessCode)
        }
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
