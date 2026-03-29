//
//  QuizWaitingRoomLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

actor QuizWaitingRoomLogic: QuizWaitingRoomInteractor {
    // MARK: - Properties
    private let presenter: QuizWaitingRoomPresenter
    private let quizParticipationService: QuizParticipationService

    private var eventsTask: Task<Void, Never>?
    private var participantsCount = 1
    private var isCreator = false
    private var currentUserID: String?
    private var quizTitle: String?
    private var participants: [QuizParticipant] = []
    private var lastServerErrorAt: Date?

    // MARK: - Lifecycle
    init(
        presenter: QuizWaitingRoomPresenter,
        quizParticipationService: QuizParticipationService
    ) {
        self.presenter = presenter
        self.quizParticipationService = quizParticipationService
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        if let connectedPayload = await quizParticipationService.currentConnectedPayload() {
            isCreator = connectedPayload.isCreator
            currentUserID = extractCurrentUserID(from: connectedPayload.sessionId)
        }
        quizTitle = await quizParticipationService.currentQuizTitle()
        participantsCount = await quizParticipationService.currentParticipantsCount()
        participants = await quizParticipationService.currentParticipants()

        await presenter.presentIsCreator(isCreator)
        await presenter.presentCurrentUserID(currentUserID)
        if let normalizedQuizTitle = normalizedQuizTitle(quizTitle) {
            await presenter.presentQuizTitle(normalizedQuizTitle)
        }
        await presenter.presentParticipantsCount(participantsCount)
        await presenter.presentParticipants(participants)
        await subscribeToEvents()
    }

    func handleLeaveAttempt() async {
        await presenter.presentLeaveConfirmation()
    }

    func handleLeaveTap() async {
        eventsTask?.cancel()
        eventsTask = nil

        await quizParticipationService.disconnect()
        await presenter.presentCloseFlow()
    }

    func handleStartQuizTap() async {
        guard isCreator, participantsCount >= 2 else {
            return
        }

        do {
            try await quizParticipationService.startQuiz()
        } catch {
            await presenter.presentServiceError(QuizParticipationServiceError.wrap(error))
        }
    }

    // MARK: - Private Methods
    private func subscribeToEvents() async {
        eventsTask?.cancel()
        let events = await quizParticipationService.makeEventStream()

        eventsTask = Task { [weak self] in
            guard let self else { return }

            for await event in events {
                await self.handle(event)
            }
        }
    }

    private func handle(_ event: QuizParticipationEvent) async {
        switch event {
        case .connectionChanged:
            break

        case .message(let message):
            await handle(message)

        case .failure(let failure):
            guard shouldPresentStreamFailure(failure) else {
                return
            }
            await presenter.presentServiceError(failure.toServiceError())
        }
    }

    private func handle(_ message: QuizParticipationMessage) async {
        switch message {
        case .connected(let payload):
            isCreator = payload.isCreator
            currentUserID = extractCurrentUserID(from: payload.sessionId)
            await presenter.presentIsCreator(isCreator)
            await presenter.presentCurrentUserID(currentUserID)

        case .participantsUpdate(let payload):
            participantsCount = max(1, payload.count)
            await presenter.presentParticipantsCount(participantsCount)
            participants = await quizParticipationService.currentParticipants()
            await presenter.presentParticipants(participants)

        case .participantsList(let payload):
            participants = payload.participants
            participantsCount = max(1, payload.participants.count)
            quizTitle = payload.quizTitle
            await presenter.presentParticipantsCount(participantsCount)
            await presenter.presentParticipants(participants)
            if let normalizedQuizTitle = normalizedQuizTitle(payload.quizTitle) {
                await presenter.presentQuizTitle(normalizedQuizTitle)
            }

        case .error(let message):
            lastServerErrorAt = Date()
            await presenter.presentServerError(message: message)

        case .quizStarted:
            eventsTask?.cancel()
            eventsTask = nil
            await presenter.presentRouteToQuizParticipating()

        case .question,
                .answerProgress,
                .answerResult,
                .leaderboard,
                .timeExpired,
                .waitingForCreator,
                .quizFinished,
                .unknown:
            break
        }
    }

    private func normalizedQuizTitle(_ title: String?) -> String? {
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedTitle.isEmpty ? nil : normalizedTitle
    }

    private func extractCurrentUserID(from sessionID: String?) -> String? {
        guard let sessionID else {
            return nil
        }

        let rawUserID = sessionID
            .split(separator: ":")
            .last
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return rawUserID.isEmpty ? nil : rawUserID
    }

    private func shouldPresentStreamFailure(_ failure: QuizParticipationStreamFailure) -> Bool {
        if failure == .connectionClosed {
            return false
        }

        if failure == .unknown,
           let lastServerErrorAt,
           Date().timeIntervalSince(lastServerErrorAt) < 2 {
            return false
        }

        return true
    }
}

// MARK: - Private Methods
private extension QuizParticipationStreamFailure {
    func toServiceError() -> QuizParticipationServiceError {
        switch self {
        case .offline:
            return .offline
        case .unauthorized:
            return .unauthorized
        case .connectionClosed:
            return .connectionClosed
        case .connectionTimeout:
            return .connectionTimeout
        case .unknown:
            return .unknown
        }
    }
}
