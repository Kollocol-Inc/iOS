//
//  TemplateCreatingRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

@MainActor
final class TemplateCreatingRouter: TemplateCreatingPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: TemplateCreatingViewController?

    private let router: TemplateCreatingRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: TemplateCreatingRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentCreateTemplateLoading(_ isLoading: Bool) async {
        await view?.displayCreateTemplateLoading(isLoading)
    }

    func presentCreateTemplateSuccess() async {
        await router.dismissTemplateCreatingScreen(shouldRefreshTemplates: true)
    }

    func presentDeleteTemplateSuccess() async {
        await router.dismissTemplateCreatingScreen(shouldRefreshTemplates: true)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentQuizTypeInfo(_ quizType: QuizType) async {
        await router.showQuizTypeInfoBottomSheet(
            title: quizType.displayName,
            description: quizType.infoDescription
        )
    }
}
