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

    // MARK: - Properties
    private var allTemplates: [QuizTemplate] = []
    private var templateSearchQuery = ""

    // MARK: - Lifecycle
    init(presenter: MyQuizzesPresenter, quizService: QuizService) {
        self.presenter = presenter
        self.quizService = quizService
    }

    // MARK: - Methods
    func fetchHostingQuizzes() async {
        do {
            let hosting = try await quizService.getHostingQuizzes()
            await presenter.presentHostingQuizzes(hosting)
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

    func routeToCreateTemplateScreen() async {
        await presenter.presentCreateTemplateScreen()
    }

    func routeToStartQuizScreen(templateId: String?) async {
        await presenter.presentStartQuizScreen(templateId: templateId)
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

    func handleTemplateSearchQueryChanged(_ query: String) {
        templateSearchQuery = query

        Task { [weak self] in
            await self?.presentFilteredTemplates()
        }
    }

    // MARK: - Private Methods
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
