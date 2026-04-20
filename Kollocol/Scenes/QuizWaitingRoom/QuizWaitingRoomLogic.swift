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
    private let quizService: QuizService
    private let accessCode: String

    private var eventsTask: Task<Void, Never>?
    private var participantsCount = 1
    private var isCreator = false
    private var currentUserID: String?
    private var quizStatus: QuizStatus?
    private var quizTitle: String?
    private var participants: [QuizParticipant] = []
    private var lastServerErrorAt: Date?
    private var hasRoutedToParticipating = false
    private var hasRequestedFlowClose = false
    private var isCancelingQuiz = false

    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Lifecycle
    init(
        presenter: QuizWaitingRoomPresenter,
        quizParticipationService: QuizParticipationService,
        quizService: QuizService,
        accessCode: String
    ) {
        self.presenter = presenter
        self.quizParticipationService = quizParticipationService
        self.quizService = quizService
        self.accessCode = accessCode
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        if let connectedPayload = await quizParticipationService.currentConnectedPayload() {
            isCreator = connectedPayload.isCreator
            currentUserID = extractCurrentUserID(from: connectedPayload.sessionId)
            quizStatus = connectedPayload.quizStatus
            logQuizFlow(
                "viewDidLoad snapshot: status=\(connectedPayload.quizStatus?.rawValue ?? "nil"), " +
                "isCreator=\(connectedPayload.isCreator), currentUserID=\(currentUserID ?? "nil")"
            )
        } else {
            logQuizFlow("viewDidLoad snapshot: connected payload is nil")
        }

        if shouldRouteToQuizParticipating() {
            logQuizFlow("viewDidLoad decided to route directly to participating")
            await routeToQuizParticipatingIfNeeded()
            return
        }

        quizTitle = await quizParticipationService.currentQuizTitle()
        participants = sortParticipants(await quizParticipationService.currentParticipants())
        participantsCount = max(1, participants.count)
        logQuizFlow(
            "waiting room state prepared: participantsCount=\(participantsCount), " +
            "participantsCached=\(participants.count), quizTitle=\(quizTitle ?? "nil")"
        )

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
        hasRequestedFlowClose = true

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

    func handleCancelQuizTap() async {
        guard isCreator else {
            return
        }

        isCancelingQuiz = true
        do {
            guard let instanceId = try await resolveCurrentInstanceID() else {
                isCancelingQuiz = false
                await presenter.presentServerError(message: "Не удалось отменить квиз")
                return
            }

            try await quizService.deleteQuizInstance(by: instanceId)

            let cachedQuizTitle = await quizParticipationService.currentQuizTitle()
            let resolvedQuizTitle = normalizedQuizTitle(quizTitle ?? cachedQuizTitle) ?? "Квиз"

            hasRequestedFlowClose = true
            eventsTask?.cancel()
            eventsTask = nil
            await quizParticipationService.disconnect()

            await presenter.presentQuizCanceled(quizTitle: resolvedQuizTitle)
        } catch {
            isCancelingQuiz = false
            await presenter.presentServiceError(QuizParticipationServiceError.wrap(error))
        }
    }

    func handleKickParticipantTap(_ participant: QuizParticipant) async {
        guard isCreator,
              quizStatus == .waiting,
              participant.isCreator == false else {
            return
        }

        guard let participantEmail = normalizedParticipantEmail(participant) else {
            await presenter.presentServerError(message: "Не удалось выгнать участника")
            return
        }

        await presenter.presentKickParticipantConfirmation(
            participantName: participantDisplayName(participant),
            participantEmail: participantEmail
        )
    }

    func handleKickParticipantConfirmed(email: String) async {
        guard isCreator,
              quizStatus == .waiting else {
            return
        }

        do {
            try await quizParticipationService.kickParticipant(email: email)
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
            if hasRequestedFlowClose || isCancelingQuiz {
                return
            }
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
            quizStatus = payload.quizStatus
            logQuizFlow(
                "connected message: status=\(payload.quizStatus?.rawValue ?? "nil"), " +
                "isCreator=\(payload.isCreator), shouldRoute=\(shouldRouteToQuizParticipating())"
            )
            await presenter.presentIsCreator(isCreator)
            await presenter.presentCurrentUserID(currentUserID)
            if shouldRouteToQuizParticipating() {
                await routeToQuizParticipatingIfNeeded()
            }

        case .participantsUpdate:
            participants = sortParticipants(await quizParticipationService.currentParticipants())
            participantsCount = max(1, participants.count)
            await presenter.presentParticipantsCount(participantsCount)
            await presenter.presentParticipants(participants)

        case .participantsList(let payload):
            participants = sortParticipants(payload.participants)
            participantsCount = max(1, participants.count)
            quizTitle = payload.quizTitle
            await presenter.presentParticipantsCount(participantsCount)
            await presenter.presentParticipants(participants)
            if let normalizedQuizTitle = normalizedQuizTitle(payload.quizTitle) {
                await presenter.presentQuizTitle(normalizedQuizTitle)
            }

        case .error(let message):
            lastServerErrorAt = Date()
            if await handleSessionReplacedIfNeeded(message) {
                return
            }
            if await handleQuizDeletedByCreatorIfNeeded(message) {
                return
            }
            if isKickedError(message) {
                let cachedQuizTitle = await quizParticipationService.currentQuizTitle()
                let resolvedQuizTitle = quizTitle ?? cachedQuizTitle
                hasRequestedFlowClose = true
                eventsTask?.cancel()
                eventsTask = nil
                await quizParticipationService.disconnect()
                await presenter.presentKickedFromQuiz(quizTitle: resolvedQuizTitle)
                return
            }
            await presenter.presentServerError(message: message)

        case .quizStarted:
            logQuizFlow("quizStarted message received in waiting room")
            await routeToQuizParticipatingIfNeeded()

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

    private func shouldRouteToQuizParticipating() -> Bool {
        quizStatus == .active
    }

    private func routeToQuizParticipatingIfNeeded() async {
        guard hasRoutedToParticipating == false else {
            logQuizFlow("routeToQuizParticipating ignored: already routed")
            return
        }

        hasRoutedToParticipating = true
        logQuizFlow(
            "routing to participating. currentStatus=\(quizStatus?.rawValue ?? "nil"), " +
            "isCreator=\(isCreator), participantsCount=\(participantsCount)"
        )
        eventsTask?.cancel()
        eventsTask = nil
        await presenter.presentRouteToQuizParticipating()
    }

    private func normalizedQuizTitle(_ title: String?) -> String? {
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedTitle.isEmpty ? nil : normalizedTitle
    }

    private func normalizedParticipantEmail(_ participant: QuizParticipant) -> String? {
        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return email.isEmpty ? nil : email
    }

    private func resolveCurrentInstanceID() async throws -> String? {
        let normalizedAccessCode = await resolveCurrentAccessCode()
        guard normalizedAccessCode.isEmpty == false else {
            return nil
        }

        let instances = try await quizService.getHostingQuizzes(status: nil)
        return instances
            .first { instance in
                let instanceAccessCode = instance.accessCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return instanceAccessCode == normalizedAccessCode
            }?
            .id?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func resolveCurrentAccessCode() async -> String {
        if case .connected(let connectedAccessCode) = await quizParticipationService.currentConnectionState() {
            let normalizedConnectedAccessCode = connectedAccessCode.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedConnectedAccessCode.isEmpty == false {
                return normalizedConnectedAccessCode
            }
        }

        return accessCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func participantDisplayName(_ participant: QuizParticipant) -> String {
        let fullName = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        if fullName.isEmpty == false {
            return fullName
        }

        if let email = normalizedParticipantEmail(participant) {
            return email
        }

        return "участника"
    }

    private func isKickedError(_ message: String) -> Bool {
        let normalizedMessage = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalizedMessage == "you have been kicked"
    }

    private func handleSessionReplacedIfNeeded(_ message: String) async -> Bool {
        guard isSessionReplacedError(message) else {
            return false
        }

        hasRequestedFlowClose = true
        eventsTask?.cancel()
        eventsTask = nil
        await quizParticipationService.disconnect()
        await presenter.presentSessionReplaced()
        return true
    }

    private func handleQuizDeletedByCreatorIfNeeded(_ message: String) async -> Bool {
        guard isQuizDeletedError(message) else {
            return false
        }

        lastServerErrorAt = Date()
        if isCancelingQuiz || hasRequestedFlowClose {
            return true
        }

        hasRequestedFlowClose = true
        eventsTask?.cancel()
        eventsTask = nil
        await quizParticipationService.disconnect()
        await presenter.presentQuizDeletedByCreator()
        return true
    }

    private func isSessionReplacedError(_ message: String) -> Bool {
        let normalizedMessage = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalizedMessage == "session replaced by another device"
    }

    private func isQuizDeletedError(_ message: String) -> Bool {
        let normalizedMessage = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalizedMessage.contains("game has been deleted")
    }

    private func sortParticipants(_ participants: [QuizParticipant]) -> [QuizParticipant] {
        participants.sorted { left, right in
            if left.isCreator != right.isCreator {
                return left.isCreator
            }

            return participantSortKey(left) < participantSortKey(right)
        }
    }

    private func participantSortKey(_ participant: QuizParticipant) -> String {
        let fullName = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
            .lowercased()

        if fullName.isEmpty == false {
            return fullName
        }

        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if email.isEmpty == false {
            return email
        }

        return participant.userId?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
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

    private func logQuizFlow(_ message: String) {
        #if DEBUG
        let timestamp = Self.logDateFormatter.string(from: Date())
        print("[QuizFlow][QuizWaitingRoomLogic][\(timestamp)] \(message)")
        #endif
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
