//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MyQuizzesLogic: MyQuizzesInteractor {
    // MARK: - Constants
    private let presenter: MyQuizzesPresenter
    private let quizService: QuizService
    private let mlService: MLService
    private let quizParticipationService: QuizParticipationService

    // MARK: - Properties
    private var allHostingQuizzes: [QuizInstance] = []
    private var allTemplates: [QuizTemplate] = []
    private var hostingSearchQuery = ""
    private var templateSearchQuery = ""

    // MARK: - Lifecycle
    init(
        presenter: MyQuizzesPresenter,
        quizService: QuizService,
        mlService: MLService,
        quizParticipationService: QuizParticipationService
    ) {
        self.presenter = presenter
        self.quizService = quizService
        self.mlService = mlService
        self.quizParticipationService = quizParticipationService
    }

    // MARK: - Methods
    func fetchHostingQuizzes() async {
        do {
            let hosting = try await quizService.getHostingQuizzes()
            allHostingQuizzes = hosting
            await presentFilteredHostingQuizzes()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func fetchTemplates() async {
        do {
            let templates = try await quizService.getTemplates()
            allTemplates = templates
            await presentFilteredTemplates()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func joinQuiz(code: String) async {
        do {
            try await quizParticipationService.connect(accessCode: code)
            await presenter.presentJoinQuizSuccess(accessCode: code)
        } catch {
            await presenter.presentJoinQuizError(QuizParticipationServiceError.wrap(error))
        }
    }

    func generateTemplate(prompt: String) async throws -> GeneratedTemplate {
        let normalizedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedPrompt.isEmpty == false else {
            throw MLServiceError.badRequest
        }

        do {
            return try await mlService.generateTemplate(.init(text: normalizedPrompt))
        } catch {
            throw MLServiceError.wrap(error)
        }
    }

    func handleTemplateGenerationError(_ error: MLServiceError) async {
        await presenter.presentTemplateGenerationError(error)
    }

    func handleQuizCardTap(_ quiz: QuizInstanceViewData) async {
        let accessCode = quiz.accessCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard accessCode.isEmpty == false else {
            return
        }

        let normalizedTitle = quiz.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        await presenter.presentJoinQuizConfirmation(
            accessCode: accessCode,
            quizTitle: normalizedTitle
        )
    }

    func routeToCreateTemplateScreen() async {
        await presenter.presentCreateTemplateScreen()
    }

    func routeToCreateTemplateScreen(from generatedTemplate: GeneratedTemplate) async {
        await presenter.presentCreateTemplateScreen(from: generatedTemplate)
    }

    func routeToStartQuizScreen(templateId: String?) async {
        guard let templateId else { return }
        guard let template = allTemplates.first(where: { $0.id == templateId }) else {
            return
        }

        await presenter.presentStartQuizScreen(template: template)
    }

    func deleteTemplate(templateId: String) async {
        do {
            try await quizService.deleteTemplate(by: templateId)
            allTemplates.removeAll { $0.id == templateId }
            await presentFilteredTemplates()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleTemplateTap(templateId: String) async {
        guard let template = allTemplates.first(where: { $0.id == templateId }) else {
            return
        }

        await presenter.presentTemplateEditingScreen(template)
    }

    func handleQuizTypeTap(_ quizType: QuizType) async {
        await presenter.presentQuizTypeInfo(quizType)
    }

    func handleHostingSearchQueryChanged(_ query: String) {
        hostingSearchQuery = query

        Task { [weak self] in
            await self?.presentFilteredHostingQuizzes()
        }
    }

    func handleTemplateSearchQueryChanged(_ query: String) {
        templateSearchQuery = query

        Task { [weak self] in
            await self?.presentFilteredTemplates()
        }
    }

    // MARK: - Private Methods
    private func presentFilteredHostingQuizzes() async {
        let normalizedQuery = hostingSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard normalizedQuery.isEmpty == false else {
            await presenter.presentHostingQuizzes(allHostingQuizzes)
            return
        }

        let filteredHostingQuizzes = allHostingQuizzes.filter { quiz in
            let titleContainsQuery = quiz.title?.localizedCaseInsensitiveContains(normalizedQuery) ?? false
            let accessCodeContainsQuery = quiz.accessCode?.localizedCaseInsensitiveContains(normalizedQuery) ?? false
            return titleContainsQuery || accessCodeContainsQuery
        }

        await presenter.presentHostingQuizzes(filteredHostingQuizzes)
    }

    private func presentFilteredTemplates() async {
        let normalizedQuery = templateSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasAnyTemplates = allTemplates.isEmpty == false

        guard normalizedQuery.isEmpty == false else {
            let emptyStateText = hasAnyTemplates ? nil : "Нет шаблонов, которые вы создали"
            await presenter.presentTemplates(sortTemplates(allTemplates), emptyStateText: emptyStateText)
            return
        }

        let filteredTemplates = allTemplates.filter { template in
            let titleContainsQuery = template.title?.localizedCaseInsensitiveContains(normalizedQuery) ?? false
            let descriptionContainsQuery = template.description?.localizedCaseInsensitiveContains(normalizedQuery) ?? false
            return titleContainsQuery || descriptionContainsQuery
        }

        let emptyStateText = filteredTemplates.isEmpty ? "Нет шаблонов с таким названием" : nil
        await presenter.presentTemplates(sortTemplates(filteredTemplates), emptyStateText: emptyStateText)
    }

    private func sortTemplates(_ templates: [QuizTemplate]) -> [QuizTemplate] {
        templates.sorted { lhs, rhs in
            switch (lhs.title, rhs.title) {
            case let (leftTitle?, rightTitle?):
                return leftTitle.localizedCaseInsensitiveCompare(rightTitle) == .orderedAscending
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return false
            }
        }
    }
}
