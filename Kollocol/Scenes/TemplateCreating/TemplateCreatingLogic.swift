//
//  TemplateCreatingLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

actor TemplateCreatingLogic: TemplateCreatingInteractor {
    // MARK: - Constants
    private let presenter: TemplateCreatingPresenter
    private let quizService: QuizService

    // MARK: - Lifecycle
    init(
        presenter: TemplateCreatingPresenter,
        quizService: QuizService
    ) {
        self.presenter = presenter
        self.quizService = quizService
    }

    // MARK: - Methods
    func createTemplate(formData: TemplateCreatingModels.FormData) async {
        await presenter.presentCreateTemplateLoading(true)

        do {
            let normalizedTitle = formData.title?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let title: String? = {
                guard let normalizedTitle, normalizedTitle.isEmpty == false else {
                    return nil
                }

                return normalizedTitle
            }()

            let request = CreateTemplateRequest(
                description: nil,
                questions: formData.questions.isEmpty ? nil : formData.questions,
                quizType: formData.quizType,
                settings: QuizSettings(
                    allowReview: nil,
                    randomOrder: formData.isRandomOrderEnabled,
                    showCorrectAnswer: nil,
                    timeLimitTotal: nil
                ),
                title: title
            )

            try await quizService.createTemplate(request)
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentCreateTemplateSuccess()
        } catch {
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleQuizTypeInfoTap(_ quizType: QuizType) async {
        await presenter.presentQuizTypeInfo(quizType)
    }
}
