//
//  QuizParticipantsOverviewLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

actor QuizParticipantsOverviewLogic: QuizParticipantsOverviewInteractor {
    // MARK: - Properties
    private let presenter: QuizParticipantsOverviewPresenter
    private let quizService: QuizService
    private let instanceId: String
    private let quizTitle: String

    // MARK: - Lifecycle
    init(
        presenter: QuizParticipantsOverviewPresenter,
        quizService: QuizService,
        instanceId: String,
        quizTitle: String
    ) {
        self.presenter = presenter
        self.quizService = quizService
        self.instanceId = instanceId
        self.quizTitle = quizTitle
    }

    // MARK: - Methods
    func fetchParticipants() async {
        do {
            let participants = try await quizService.getQuizInstanceParticipants(by: instanceId)
            await presenter.presentParticipants(participants)
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func publishQuizResults() async {
        do {
            try await quizService.publishQuizResults(instanceId: instanceId)
            await presenter.presentPublishQuizResultsSuccess()
        } catch {
            await presenter.presentServiceError(QuizServiceError.wrap(error))
        }
    }

    func handleParticipantTap(
        participantId: String?,
        fullName: String,
        email: String?
    ) async {
        let normalizedParticipantID = participantId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard normalizedParticipantID.isEmpty == false else {
            return
        }

        await presenter.presentParticipantReview(
            .init(
                instanceId: instanceId,
                participantId: normalizedParticipantID,
                participantFullName: fullName,
                participantEmail: email,
                quizTitle: quizTitle
            )
        )
    }
}
