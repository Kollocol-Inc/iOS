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
    private let mlService: MLService

    // MARK: - Lifecycle
    init(
        presenter: TemplateCreatingPresenter,
        quizService: QuizService,
        mlService: MLService
    ) {
        self.presenter = presenter
        self.quizService = quizService
        self.mlService = mlService
    }

    // MARK: - Methods
    func createTemplate(formData: TemplateCreatingModels.FormData) async {
        await presenter.presentCreateTemplateLoading(true)

        do {
            let request = makeTemplateRequest(from: formData)
            try await quizService.createTemplate(request)
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentCreateTemplateSuccess()
        } catch {
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func updateTemplate(by templateId: String, formData: TemplateCreatingModels.FormData) async {
        await presenter.presentCreateTemplateLoading(true)

        do {
            let request = makeTemplateRequest(from: formData)
            try await quizService.updateTemplate(by: templateId, request)
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentCreateTemplateSuccess()
        } catch {
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func deleteTemplate(by templateId: String) async {
        await presenter.presentCreateTemplateLoading(true)

        do {
            try await quizService.deleteTemplate(by: templateId)
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentDeleteTemplateSuccess()
        } catch {
            await presenter.presentCreateTemplateLoading(false)
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func paraphraseQuestionText(_ text: String) async throws -> String {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedText.isEmpty == false else {
            return normalizedText
        }

        do {
            let response = try await mlService.paraphrase(.init(text: normalizedText))
            let paraphrasedText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return paraphrasedText.isEmpty ? normalizedText : paraphrasedText
        } catch {
            throw MLServiceError.wrap(error)
        }
    }

    func handleQuizTypeInfoTap(_ quizType: QuizType) async {
        await presenter.presentQuizTypeInfo(quizType)
    }

    // MARK: - Private Methods
    private func makeTemplateRequest(from formData: TemplateCreatingModels.FormData) -> CreateTemplateRequest {
        let normalizedTitle = formData.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String? = {
            guard let normalizedTitle, normalizedTitle.isEmpty == false else {
                return nil
            }

            return normalizedTitle
        }()

        return CreateTemplateRequest(
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
    }
}
