//
//  StartQuizLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

actor StartQuizLogic: StartQuizInteractor {
    // MARK: - Properties
    private let presenter: StartQuizPresenter
    private let quizService: QuizService
    private let groupService: GroupService
    private let quizParticipationService: QuizParticipationService
    private let template: QuizTemplate

    // MARK: - Lifecycle
    init(
        presenter: StartQuizPresenter,
        quizService: QuizService,
        groupService: GroupService,
        quizParticipationService: QuizParticipationService,
        template: QuizTemplate
    ) {
        self.presenter = presenter
        self.quizService = quizService
        self.groupService = groupService
        self.quizParticipationService = quizParticipationService
        self.template = template
    }

    // MARK: - Methods
    func fetchOwnedGroups() async {
        do {
            let groups = try await groupService.getGroups(filter: .created)
            await presenter.presentOwnedGroups(groups)
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleBackTap() async {
        await presenter.presentCloseScreen()
    }

    func startQuiz(formData: StartQuizModels.FormData) async {
        await presenter.presentStartQuizLoading(true)

        do {
            let request = makeCreateInstanceRequest(from: formData)
            let accessCode = try await quizService.createQuizInstance(request)

            guard template.quizType == .sync else {
                await presenter.presentStartQuizLoading(false)
                await presenter.presentStartQuizSuccess()
                return
            }

            let normalizedAccessCode = accessCode?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let normalizedAccessCode, normalizedAccessCode.isEmpty == false else {
                await presenter.presentStartQuizLoading(false)
                await presenter.presentServiceError(.unknown)
                return
            }

            do {
                try await quizParticipationService.connect(accessCode: normalizedAccessCode)
                await presenter.presentStartQuizLoading(false)
                await presenter.presentStartSyncQuizSuccess(accessCode: normalizedAccessCode)
            } catch {
                await presenter.presentStartQuizLoading(false)
                await presenter.presentJoinQuizError(QuizParticipationServiceError.wrap(error))
            }
        } catch {
            await presenter.presentStartQuizLoading(false)
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    // MARK: - Private Methods
    private func makeCreateInstanceRequest(from formData: StartQuizModels.FormData) -> CreateInstanceRequest {
        let normalizedGroupId = formData.groupId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let groupId: String? = {
            guard let normalizedGroupId, normalizedGroupId.isEmpty == false else {
                return nil
            }
            return normalizedGroupId
        }()

        let normalizedTitle = formData.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let title: String? = {
            guard let normalizedTitle, normalizedTitle.isEmpty == false else {
                return nil
            }

            return normalizedTitle
        }()

        let deadline: Date? = {
            guard template.quizType == .async else {
                return nil
            }

            return formData.deadline
        }()

        return CreateInstanceRequest(
            deadline: deadline,
            groupId: groupId,
            templateId: template.id,
            title: title
        )
    }
}
