//
//  QuizParticipatingLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

actor QuizParticipatingLogic: QuizParticipatingInteractor {
    // MARK: - Constants
    private enum Constants {
        static let participantSubmitButtonTitle = "Ответить"
        static let participantWaitingButtonTitle = "Ожидаем следующего вопроса"
        static let creatorWaitingButtonTitle = "Ожидаем ответа всех участников"
        static let creatorNextQuestionButtonTitle = "Следующий вопрос"
        static let finalExitButtonTitle = "Выйти"
    }

    // MARK: - Properties
    private let presenter: QuizParticipatingPresenter
    private let quizParticipationService: QuizParticipationService
    private let quizService: QuizService

    private var eventsTask: Task<Void, Never>?
    private var hasRequestedFlowClose = false
    private var isCancelingQuiz = false

    private var isCreator = false
    private var currentQuizStatus: QuizStatus?
    private var currentQuizType: QuizType?
    private var phase: QuizParticipatingModels.Phase = .participantAnswering
    private var questionPayload: QuizQuestionPayload?
    private var openAnswerText = ""
    private var selectedOptionIndexes: Set<Int> = []
    private var leaderboardEntries: [QuizLeaderboardEntryPayload] = []
    private var answerOptionStats: [QuizAnswerOptionStatsPayload] = []
    private var canCreatorContinueCurrentQuestion = false
    private var currentParticipants: [QuizParticipant] = []
    private var currentUserID: String?
    private var participantScoresByID: [String: Int] = [:]
    private var answeredParticipantIDs: Set<String> = []
    private var participantsAnsweredCount = 0
    private var totalParticipantsCount = 0
    private var questionDisplayedAt: Date?
    private var lastServerErrorAt: Date?
    private var quizTitle: String?
    private var quizFinishedPayload: QuizFinishedPayload?

    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    // MARK: - Lifecycle
    init(
        presenter: QuizParticipatingPresenter,
        quizParticipationService: QuizParticipationService,
        quizService: QuizService
    ) {
        self.presenter = presenter
        self.quizParticipationService = quizParticipationService
        self.quizService = quizService
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        if let connectedPayload = await quizParticipationService.currentConnectedPayload() {
            isCreator = connectedPayload.isCreator
            currentUserID = extractCurrentUserID(from: connectedPayload.sessionId)
            currentQuizStatus = connectedPayload.quizStatus
            currentQuizType = connectedPayload.quizType
            logQuizFlow(
                "viewDidLoad snapshot: status=\(connectedPayload.quizStatus?.rawValue ?? "nil"), " +
                "type=\(connectedPayload.quizType?.rawValue ?? "nil"), " +
                "isCreator=\(connectedPayload.isCreator), currentUserID=\(currentUserID ?? "nil")"
            )
        } else {
            logQuizFlow("viewDidLoad snapshot: connected payload is nil")
        }

        currentParticipants = await quizParticipationService.currentParticipants()
        let initialLeaderboardPayload = await quizParticipationService.currentLeaderboardPayload()
        leaderboardEntries = initialLeaderboardPayload?.leaderboard ?? []
        answerOptionStats = initialLeaderboardPayload?.answerOptionStats ?? []
        canCreatorContinueCurrentQuestion = initialLeaderboardPayload?.canContinue ?? false
        quizTitle = await quizParticipationService.currentQuizTitle()
        let initialQuestionPayload = await quizParticipationService.currentQuestionPayload()
        logQuizFlow(
            "viewDidLoad cache: participants=\(currentParticipants.count), " +
            "leaderboardEntries=\(leaderboardEntries.count), " +
            "canContinue=\(canCreatorContinueCurrentQuestion), " +
            "hasQuestion=\(initialQuestionPayload != nil)"
        )
        updateParticipantCacheFromLeaderboard(leaderboardEntries)
        updateAnswerProgressFromLeaderboard(leaderboardEntries)
        updateAnswerProgressFromParticipants()

        if let questionPayload = initialQuestionPayload {
            applyNewQuestion(questionPayload)
            if isCreator {
                updateAnsweredParticipantsFromLeaderboard(leaderboardEntries)
                updateCreatorPhaseFromContinueAvailability()
            } else if shouldUseParticipantWaitingForCreatorPhase,
                      leaderboardEntries.isEmpty == false {
                phase = .participantWaitingForCreator
            }
            logQuizFlow(
                "viewDidLoad applied question: index=\(questionPayload.questionIndex), " +
                "type=\(questionPayload.question.type?.rawValue ?? "nil"), phase=\(phase.logDescription)"
            )
        } else if applyQuestionFallbackFromLeaderboardIfNeeded(initialLeaderboardPayload) {
            if isCreator {
                updateAnsweredParticipantsFromLeaderboard(leaderboardEntries)
                updateCreatorPhaseFromContinueAvailability()
            } else if shouldUseParticipantWaitingForCreatorPhase,
                      leaderboardEntries.isEmpty == false {
                phase = .participantWaitingForCreator
            }
            logQuizFlow("viewDidLoad restored question from leaderboard fallback. phase=\(phase.logDescription)")
        } else {
            applyMissingQuestionPhase()
        }

        if let normalizedQuizTitle = normalizedQuizTitle(quizTitle) {
            await presenter.presentQuizTitle(normalizedQuizTitle)
        }

        await presentCurrentState()
        await subscribeToEvents()
        await synchronizeStateAfterSubscription()
    }

    func handleLeaveAttempt() async {
        if phase == .quizFinished {
            await handleLeaveTap()
        } else {
            await presenter.presentLeaveConfirmation()
        }
    }

    func handleLeaveTap() async {
        eventsTask?.cancel()
        eventsTask = nil
        hasRequestedFlowClose = true

        await quizParticipationService.disconnect()
        await presenter.presentCloseFlow()
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
            await presenter.presentServerError(message: "Не удалось отменить квиз")
        }
    }

    func handleSubmitTap() async {
        if phase == .quizFinished {
            await handleLeaveTap()
            return
        }

        if isCreator {
            await handleCreatorContinueTap()
            return
        }

        guard phase == .participantAnswering,
              let questionPayload,
              let questionId = questionPayload.question.id,
              let answer = makeAnswer(for: questionPayload.question) else {
            return
        }

        let timeSpentMs = calculateTimeSpentMs()

        do {
            try await quizParticipationService.sendAnswer(
                questionId: questionId,
                answer: answer,
                timeSpentMs: timeSpentMs
            )
            phase = .participantSubmittedWaitingOthers
            updateAnswerProgressFromParticipants()
            participantsAnsweredCount = max(1, participantsAnsweredCount)
            await presentCurrentState()
        } catch {
            await presenter.presentServiceError(QuizParticipationServiceError.wrap(error))
        }
    }

    func handleOptionTap(_ index: Int) async {
        guard isCreator == false,
              phase == .participantAnswering,
              let questionType = questionPayload?.question.type else {
            return
        }

        switch questionType {
        case .singleChoice:
            selectedOptionIndexes = [index]

        case .multiChoice:
            if selectedOptionIndexes.contains(index) {
                selectedOptionIndexes.remove(index)
            } else {
                selectedOptionIndexes.insert(index)
            }

        case .openEnded:
            return
        }

        await presentCurrentState()
    }

    func handleOpenAnswerTextChanged(_ text: String) async {
        guard isCreator == false,
              phase == .participantAnswering,
              questionPayload?.question.type == .openEnded else {
            return
        }

        openAnswerText = text
        await presentCurrentState()
    }

    // MARK: - Private Methods
    private func synchronizeStateAfterSubscription() async {
        if let connectedPayload = await quizParticipationService.currentConnectedPayload() {
            currentUserID = extractCurrentUserID(from: connectedPayload.sessionId)
            currentQuizStatus = connectedPayload.quizStatus
            currentQuizType = connectedPayload.quizType
        }

        currentParticipants = await quizParticipationService.currentParticipants()
        let latestLeaderboardPayload = await quizParticipationService.currentLeaderboardPayload()
        leaderboardEntries = latestLeaderboardPayload?.leaderboard ?? []
        answerOptionStats = latestLeaderboardPayload?.answerOptionStats ?? []
        canCreatorContinueCurrentQuestion = latestLeaderboardPayload?.canContinue ?? false
        quizTitle = await quizParticipationService.currentQuizTitle()
        updateParticipantCacheFromLeaderboard(leaderboardEntries)
        updateAnswerProgressFromLeaderboard(leaderboardEntries)
        updateAnswerProgressFromParticipants()

        if let latestQuestionPayload = await quizParticipationService.currentQuestionPayload() {
            if questionIdentity(for: questionPayload) != questionIdentity(for: latestQuestionPayload) {
                applyNewQuestion(latestQuestionPayload)
            } else if shouldUseParticipantWaitingForCreatorPhase,
                      leaderboardEntries.isEmpty == false {
                phase = .participantWaitingForCreator
            }
            logQuizFlow(
                "sync snapshot with question: index=\(latestQuestionPayload.questionIndex), " +
                "phase=\(phase.logDescription), canContinue=\(canCreatorContinueCurrentQuestion)"
            )
        } else if applyQuestionFallbackFromLeaderboardIfNeeded(latestLeaderboardPayload) {
            if isCreator {
                updateAnsweredParticipantsFromLeaderboard(leaderboardEntries)
                updateCreatorPhaseFromContinueAvailability()
            } else if shouldUseParticipantWaitingForCreatorPhase,
                      leaderboardEntries.isEmpty == false {
                phase = .participantWaitingForCreator
            }
            logQuizFlow(
                "sync snapshot restored question from leaderboard fallback. " +
                "phase=\(phase.logDescription), canContinue=\(canCreatorContinueCurrentQuestion)"
            )
        } else {
            applyMissingQuestionPhase()
            logQuizFlow(
                "sync snapshot without question: status=\(currentQuizStatus?.rawValue ?? "nil"), " +
                "phase=\(phase.logDescription), canContinue=\(canCreatorContinueCurrentQuestion)"
            )
        }

        if isCreator {
            updateAnsweredParticipantsFromLeaderboard(leaderboardEntries)
            updateCreatorPhaseFromContinueAvailability()
        }

        if let normalizedQuizTitle = normalizedQuizTitle(quizTitle) {
            await presenter.presentQuizTitle(normalizedQuizTitle)
        }

        await presentCurrentState()
    }

    private func handleCreatorContinueTap() async {
        guard phase == .creatorReadyToContinue else {
            return
        }

        do {
            try await quizParticipationService.sendCommand(type: "continue")
            canCreatorContinueCurrentQuestion = false
            phase = .creatorWaitingParticipants
            await presentCurrentState()
        } catch {
            await presenter.presentServiceError(QuizParticipationServiceError.wrap(error))
        }
    }

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
        case .connectionChanged(let state):
            if case .disconnected = state,
               hasRequestedFlowClose == false {
                hasRequestedFlowClose = true
                await presenter.presentCloseFlow()
            }

        case .failure(let failure):
            if hasRequestedFlowClose || isCancelingQuiz {
                return
            }
            guard shouldPresentStreamFailure(failure) else {
                return
            }
            await presenter.presentServiceError(failure.toServiceError())

        case .message(let message):
            await handle(message)
        }
    }

    private func handle(_ message: QuizParticipationMessage) async {
        if phase == .quizFinished {
            switch message {
            case .connected(let payload):
                isCreator = payload.isCreator
                currentUserID = extractCurrentUserID(from: payload.sessionId)
                currentQuizType = payload.quizType

            case .error(let message):
                if await handleSessionReplacedIfNeeded(message) {
                    return
                }
                if await handleKickedFromQuizIfNeeded(message) {
                    return
                }
                if await handleQuizDeletedByCreatorIfNeeded(message) {
                    return
                }
                lastServerErrorAt = Date()
                await presenter.presentServerError(message: message)

            case .quizFinished,
                    .participantsUpdate,
                    .participantsList,
                    .question,
                    .leaderboard,
                    .answerProgress,
                    .answerResult,
                    .timeExpired,
                    .waitingForCreator,
                    .quizStarted,
                    .unknown:
                break
            }
            return
        }

        switch message {
        case .connected(let payload):
            isCreator = payload.isCreator
            currentUserID = extractCurrentUserID(from: payload.sessionId)
            currentQuizStatus = payload.quizStatus
            currentQuizType = payload.quizType
            logQuizFlow(
                "connected message: status=\(payload.quizStatus?.rawValue ?? "nil"), " +
                "type=\(payload.quizType?.rawValue ?? "nil"), " +
                "isCreator=\(payload.isCreator), phase=\(phase.logDescription)"
            )

        case .participantsUpdate:
            currentParticipants = await quizParticipationService.currentParticipants()
            updateAnswerProgressFromParticipants()

            if isCreator {
                await presentCurrentState()
            } else if phase == .participantWaitingForCreator || phase == .participantSubmittedWaitingOthers {
                await presentCurrentState()
            }

        case .participantsList(let payload):
            currentParticipants = payload.participants
            quizTitle = payload.quizTitle
            updateAnswerProgressFromParticipants()

            if isCreator {
                await presentCurrentState()
            } else if phase == .participantWaitingForCreator || phase == .participantSubmittedWaitingOthers {
                await presentCurrentState()
            }

            if let normalizedQuizTitle = normalizedQuizTitle(payload.quizTitle) {
                await presenter.presentQuizTitle(normalizedQuizTitle)
            }

        case .question(let payload):
            logQuizFlow(
                "question message: index=\(payload.questionIndex), total=\(payload.totalQuestions), " +
                "type=\(payload.question.type?.rawValue ?? "nil"), timeLimitMs=\(payload.timeLimitMs ?? 0), " +
                "serverTime=\(payload.serverTime ?? 0)"
            )
            applyNewQuestion(payload)
            await presentCurrentState()

        case .leaderboard(let payload):
            logQuizFlow(
                "leaderboard message: entries=\(payload.leaderboard.count), " +
                "canContinue=\(payload.canContinue), optionStats=\(payload.answerOptionStats.count)"
            )
            leaderboardEntries = payload.leaderboard
            answerOptionStats = payload.answerOptionStats
            let restoredQuestionFromLeaderboard = applyQuestionFallbackFromLeaderboardIfNeeded(payload)
            updateParticipantCacheFromLeaderboard(payload.leaderboard)
            updateAnswerProgressFromLeaderboard(payload.leaderboard)
            updateAnswerProgressFromParticipants()
            if phase == .quizFinished {
                await presentCurrentState()
                break
            }

            if isCreator {
                canCreatorContinueCurrentQuestion = payload.canContinue
                updateCreatorPhaseFromContinueAvailability()
                logQuizFlow("leaderboard applied for creator. phase=\(phase.logDescription)")
                await presentCurrentState()
            } else {
                if shouldUseParticipantWaitingForCreatorPhase {
                    phase = .participantWaitingForCreator
                }
                clearAnswerSelection()
                logQuizFlow("leaderboard applied for participant. phase=\(phase.logDescription)")
                await presentCurrentState()
            }

            if restoredQuestionFromLeaderboard {
                logQuizFlow("question restored from leaderboard payload during active stream")
            }

        case .answerProgress(let payload):
            let participantsTotalFromPayload = max(0, payload.totalParticipants)
            let participantsTotalFromList = nonCreatorParticipants().count
            if participantsTotalFromList > 0 {
                totalParticipantsCount = participantsTotalFromList
            } else if isCreator {
                totalParticipantsCount = 0
            } else {
                totalParticipantsCount = participantsTotalFromPayload
            }
            participantsAnsweredCount = min(
                max(0, payload.participantsAnswered),
                totalParticipantsCount
            )
            updateAnswerProgressFromParticipants()

            if isCreator, phase == .creatorWaitingParticipants {
                await presentCurrentState()
            } else if isCreator == false, phase == .participantSubmittedWaitingOthers {
                await presentCurrentState()
            }

        case .answerResult:
            break

        case .timeExpired:
            if isCreator {
                phase = .creatorWaitingParticipants
                await presentCurrentState()
            }

        case .waitingForCreator:
            if isCreator {
                if phase == .creatorWaitingParticipants {
                    logQuizFlow("waiting_for_creator message for creator. phase=\(phase.logDescription)")
                    await presentCurrentState()
                }
            } else {
                if shouldUseParticipantWaitingForCreatorPhase {
                    phase = .participantWaitingForCreator
                    logQuizFlow("waiting_for_creator message for participant. phase=\(phase.logDescription)")
                    await presentCurrentState()
                }
            }

        case .quizFinished(let payload):
            quizFinishedPayload = payload
            if let latestLeaderboardPayload = await quizParticipationService.currentLeaderboardPayload() {
                leaderboardEntries = latestLeaderboardPayload.leaderboard
                answerOptionStats = latestLeaderboardPayload.answerOptionStats
                canCreatorContinueCurrentQuestion = latestLeaderboardPayload.canContinue
                updateParticipantCacheFromLeaderboard(latestLeaderboardPayload.leaderboard)
                updateAnswerProgressFromLeaderboard(latestLeaderboardPayload.leaderboard)
                updateAnswerProgressFromParticipants()
            }

            phase = .quizFinished
            questionPayload = nil
            clearAnswerSelection()
            await presentCurrentState()

        case .error(let message):
            if await handleSessionReplacedIfNeeded(message) {
                break
            }
            if await handleKickedFromQuizIfNeeded(message) {
                break
            }
            if await handleQuizDeletedByCreatorIfNeeded(message) {
                break
            }
            lastServerErrorAt = Date()
            await presenter.presentServerError(message: message)

        case .quizStarted:
            if let latestQuestionPayload = await quizParticipationService.currentQuestionPayload() {
                applyNewQuestion(latestQuestionPayload)
                if isCreator {
                    updateAnsweredParticipantsFromLeaderboard(leaderboardEntries)
                }
                logQuizFlow(
                    "quizStarted message applied question from cache. " +
                    "index=\(latestQuestionPayload.questionIndex), phase=\(phase.logDescription)"
                )
                await presentCurrentState()
            } else {
                logQuizFlow("quizStarted message received, but question is still nil in cache")
            }

        case .unknown:
            break
        }
    }

    private func applyNewQuestion(_ payload: QuizQuestionPayload) {
        questionPayload = payload
        phase = isCreator ? .creatorWaitingParticipants : .participantAnswering
        clearAnswerSelection()
        leaderboardEntries = []
        answerOptionStats = []
        canCreatorContinueCurrentQuestion = false
        quizFinishedPayload = nil
        answeredParticipantIDs.removeAll()
        participantsAnsweredCount = 0
        totalParticipantsCount = nonCreatorParticipants().count
        updateAnswerProgressFromParticipants()
        questionDisplayedAt = Date()
    }

    private func applyMissingQuestionPhase() {
        if currentQuizStatus == .active {
            if isCreator {
                phase = .creatorWaitingParticipants
            } else if shouldUseParticipantWaitingForCreatorPhase {
                phase = .participantWaitingForCreator
            } else {
                phase = .participantAnswering
            }
            logQuizFlow(
                "applyMissingQuestionPhase: status=active -> phase=\(phase.logDescription), " +
                "isCreator=\(isCreator)"
            )
            return
        }

        phase = isCreator ? .creatorWaitingParticipants : .participantAnswering
        logQuizFlow(
            "applyMissingQuestionPhase: status=\(currentQuizStatus?.rawValue ?? "nil") -> " +
            "phase=\(phase.logDescription), isCreator=\(isCreator)"
        )
    }

    private func applyQuestionFallbackFromLeaderboardIfNeeded(_ payload: QuizLeaderboardPayload?) -> Bool {
        guard questionPayload == nil,
              let question = payload?.question else {
            return false
        }

        questionPayload = question
        return true
    }

    private func clearAnswerSelection() {
        openAnswerText = ""
        selectedOptionIndexes.removeAll()
    }

    private var isAsyncParticipant: Bool {
        currentQuizType == .async && isCreator == false
    }

    private var shouldUseParticipantWaitingForCreatorPhase: Bool {
        isAsyncParticipant == false && isCreator == false
    }

    private var shouldShowAsyncCompletionState: Bool {
        phase == .quizFinished && isAsyncParticipant
    }

    private func presentCurrentState() async {
        let participantRows = isCreator
        ? makeCreatorParticipantRows()
        : makeParticipantRowsForParticipantMode()
        let waitingProgress = waitingProgressViewData()
        let finalLeaderboardViewData = makeFinalLeaderboardViewData()

        let state = QuizParticipatingModels.ViewState(
            questionPayload: questionPayload,
            openAnswerText: openAnswerText,
            selectedOptionIndexes: selectedOptionIndexes.sorted(),
            phase: phase,
            isCreator: isCreator,
            isAsyncQuiz: currentQuizType == .async,
            participantRows: participantRows,
            optionAnswerCounts: makeOptionAnswerCounts(),
            waitingAnsweredCount: waitingProgress.answeredCount,
            waitingTotalParticipantsCount: waitingProgress.totalCount,
            bottomButtonTitle: bottomButtonTitle(),
            isBottomButtonEnabled: isBottomButtonEnabled(),
            isTimerVisible: isTimerVisible(),
            topLeaders: finalLeaderboardViewData.topLeaders,
            personalResult: finalLeaderboardViewData.personalResult,
            finalParticipants: finalLeaderboardViewData.finalParticipants
        )

        await presenter.presentState(state)
    }

    private func makeParticipantRowsForParticipantMode() -> [QuizParticipatingModels.ParticipantRowViewData] {
        guard phase == .participantWaitingForCreator else {
            return []
        }

        return makeRankedParticipantRows().map { row in
            .init(
                participant: row.participant,
                isDimmed: false,
                isOffline: row.isOffline,
                place: row.place,
                score: row.score
            )
        }
    }

    private func makeFinalLeaderboardViewData() -> (
        topLeaders: [QuizParticipatingModels.FinalTopLeaderViewData],
        personalResult: QuizParticipatingModels.PersonalResultViewData?,
        finalParticipants: [QuizParticipatingModels.FinalParticipantRowViewData]
    ) {
        guard phase == .quizFinished else {
            return ([], nil, [])
        }

        if shouldShowAsyncCompletionState {
            return ([], nil, [])
        }

        let normalizedEntries = normalizedLeaderboardEntries()
        let topLeaders = normalizedEntries.prefix(3).map { entry in
            QuizParticipatingModels.FinalTopLeaderViewData(
                participant: entry.user,
                rank: entry.displayRank,
                score: entry.score
            )
        }
        let finalParticipants = normalizedEntries.dropFirst(3).map { entry in
            QuizParticipatingModels.FinalParticipantRowViewData(
                participant: entry.user,
                rank: entry.displayRank,
                score: entry.score
            )
        }

        return (
            topLeaders,
            makePersonalResult(from: normalizedEntries),
            finalParticipants
        )
    }

    private func makePersonalResult(
        from entries: [NormalizedLeaderboardEntry]
    ) -> QuizParticipatingModels.PersonalResultViewData? {
        guard isCreator == false else {
            return nil
        }

        if let currentUserEntry = entries.first(where: { isCurrentUser($0.user) }) {
            return .init(
                place: currentUserEntry.displayRank,
                score: currentUserEntry.score
            )
        }

        guard let quizFinishedPayload else {
            return nil
        }

        guard let rawRank = quizFinishedPayload.rank else {
            return nil
        }

        let hasZeroBasedRanks = entries.contains { $0.rawRank == 0 }
        let normalizedRank = normalizedRank(from: rawRank, hasZeroBasedRanks: hasZeroBasedRanks)
        let score = quizFinishedPayload.finalScore ?? 0

        return .init(
            place: normalizedRank,
            score: score
        )
    }

    private func normalizedLeaderboardEntries() -> [NormalizedLeaderboardEntry] {
        let participantEntries = leaderboardEntries
            .filter { $0.user.isCreator == false }
            .sorted { left, right in
                if left.rank == right.rank {
                    return left.score > right.score
                }
                return left.rank < right.rank
            }

        let hasZeroBasedRanks = participantEntries.contains { $0.rank == 0 }
        return participantEntries.map { entry in
            .init(
                user: entry.user,
                rawRank: entry.rank,
                displayRank: normalizedRank(from: entry.rank, hasZeroBasedRanks: hasZeroBasedRanks),
                score: entry.score
            )
        }
    }

    private func normalizedRank(from rawRank: Int, hasZeroBasedRanks: Bool) -> Int {
        if hasZeroBasedRanks || rawRank == 0 {
            return max(1, rawRank + 1)
        }

        return max(1, rawRank)
    }

    private func makeOptionAnswerCounts() -> [Int: Int] {
        guard let options = questionPayload?.question.options else {
            return [:]
        }

        var optionCountsQueueByText: [String: [Int]] = [:]
        for optionStats in answerOptionStats {
            optionCountsQueueByText[optionStats.option, default: []].append(optionStats.count)
        }

        var countsByIndex: [Int: Int] = [:]
        for (index, optionText) in options.enumerated() {
            let queue = optionCountsQueueByText[optionText] ?? []
            guard queue.isEmpty == false else {
                countsByIndex[index] = 0
                continue
            }

            countsByIndex[index] = queue[0]
            optionCountsQueueByText[optionText] = Array(queue.dropFirst())
        }

        return countsByIndex
    }

    private func waitingProgressViewData() -> (answeredCount: Int, totalCount: Int) {
        let participantsFromList = activeParticipantsForProgressCount()
        let fallbackTotal = isCreator ? participantsFromList : max(1, participantsFromList)
        let normalizedTotal = max(totalParticipantsCount, fallbackTotal)
        let normalizedAnswered = min(max(0, participantsAnsweredCount), normalizedTotal)
        return (normalizedAnswered, normalizedTotal)
    }

    private func updateAnswerProgressFromParticipants() {
        let participantsFromList = activeParticipantsForProgressCount()
        if totalParticipantsCount <= 0 {
            totalParticipantsCount = participantsFromList
        }

        if totalParticipantsCount <= 0, isCreator == false {
            totalParticipantsCount = 1
        }

        participantsAnsweredCount = min(
            max(0, participantsAnsweredCount),
            max(0, totalParticipantsCount)
        )
    }

    private func updateAnswerProgressFromLeaderboard(_ entries: [QuizLeaderboardEntryPayload]) {
        let participantEntries = entries.filter { $0.user.isCreator == false }
        if participantEntries.isEmpty, isCreator {
            totalParticipantsCount = 0
            participantsAnsweredCount = 0
            return
        }
        guard participantEntries.isEmpty == false else {
            return
        }

        totalParticipantsCount = participantEntries.count
        participantsAnsweredCount = participantEntries.filter(\.isAnswered).count
    }

    private func makeCreatorParticipantRows() -> [QuizParticipatingModels.ParticipantRowViewData] {
        makeRankedParticipantRows().map { row in
            return .init(
                participant: row.participant,
                isDimmed: row.isAnswered == false,
                isOffline: row.isOffline,
                place: row.place,
                score: row.score
            )
        }
    }

    private func makeRankedParticipantRows() -> [RankedParticipantRow] {
        let participants = nonCreatorParticipants()
        guard participants.isEmpty == false else {
            return []
        }

        let baseRows = participants.map { participant -> RankedParticipantRow in
            let key = participantKey(for: participant)
            let score = key.flatMap { participantScoresByID[$0] } ?? 0
            let isAnswered = isParticipantAnswered(participant)
            let isOffline = isParticipantOnline(participant) == false

            return .init(
                participant: participant,
                score: score,
                isAnswered: isAnswered,
                isOffline: isOffline,
                place: 0
            )
        }

        let sortedRows = baseRows.sorted { left, right in
            if left.score != right.score {
                return left.score > right.score
            }

            return participantSortKey(left.participant) < participantSortKey(right.participant)
        }

        return sortedRows.enumerated().map { index, row in
            .init(
                participant: row.participant,
                score: row.score,
                isAnswered: row.isAnswered,
                isOffline: row.isOffline,
                place: index + 1
            )
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

    private func nonCreatorParticipants() -> [QuizParticipant] {
        currentParticipants.filter { $0.isCreator == false }
    }

    private func isParticipantOnline(_ participant: QuizParticipant) -> Bool {
        participant.isOnline ?? true
    }

    private func isParticipantAnswered(_ participant: QuizParticipant) -> Bool {
        guard let key = participantKey(for: participant) else {
            return false
        }

        return answeredParticipantIDs.contains(key)
    }

    private func participantKey(for participant: QuizParticipant) -> String? {
        if let userID = participant.userId?.trimmingCharacters(in: .whitespacesAndNewlines),
           userID.isEmpty == false {
            return userID
        }

        if let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines),
           email.isEmpty == false {
            return email
        }

        return nil
    }

    private func isCurrentUser(_ participant: QuizParticipant) -> Bool {
        guard let currentUserID else {
            return false
        }

        return normalizeUserID(participant.userId) == currentUserID
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

    private func normalizeUserID(_ userID: String?) -> String? {
        let normalizedUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedUserID.isEmpty ? nil : normalizedUserID
    }

    private func updateAnsweredParticipantsFromLeaderboard(_ entries: [QuizLeaderboardEntryPayload]) {
        updateParticipantCacheFromLeaderboard(entries)
    }

    private func updateCreatorPhaseFromContinueAvailability() {
        guard isCreator else {
            return
        }

        phase = canCreatorContinueCurrentQuestion
        ? .creatorReadyToContinue
        : .creatorWaitingParticipants
    }

    private func updateParticipantCacheFromLeaderboard(_ entries: [QuizLeaderboardEntryPayload]) {
        var answeredKeys: Set<String> = []

        for entry in entries where entry.user.isCreator == false {
            guard let key = participantKey(for: entry.user) else {
                continue
            }

            participantScoresByID[key] = entry.score
            if entry.isAnswered {
                answeredKeys.insert(key)
            }
        }

        answeredParticipantIDs = answeredKeys
    }

    private func activeParticipantsForProgressCount() -> Int {
        nonCreatorParticipants().filter { $0.isOnline != false }.count
    }

    private func bottomButtonTitle() -> String {
        if phase == .quizFinished {
            return Constants.finalExitButtonTitle
        }

        if isCreator {
            switch phase {
            case .creatorReadyToContinue:
                return Constants.creatorNextQuestionButtonTitle
            case .creatorWaitingParticipants,
                    .participantAnswering,
                    .participantSubmittedWaitingOthers,
                    .participantWaitingForCreator,
                    .quizFinished:
                return Constants.creatorWaitingButtonTitle
            }
        }

        switch phase {
        case .participantWaitingForCreator:
            return Constants.participantWaitingButtonTitle
        case .participantSubmittedWaitingOthers:
            return Constants.participantWaitingButtonTitle
        case .participantAnswering,
                .creatorWaitingParticipants,
                .creatorReadyToContinue,
                .quizFinished:
            return Constants.participantSubmitButtonTitle
        }
    }

    private func isTimerVisible() -> Bool {
        if phase == .participantSubmittedWaitingOthers,
           isAsyncParticipant {
            return false
        }

        switch phase {
        case .participantWaitingForCreator,
                .creatorReadyToContinue,
                .quizFinished:
            return false
        case .participantAnswering,
                .participantSubmittedWaitingOthers,
                .creatorWaitingParticipants:
            return true
        }
    }

    private func isBottomButtonEnabled() -> Bool {
        if phase == .quizFinished {
            return true
        }

        if isCreator {
            return phase == .creatorReadyToContinue
        }

        guard phase == .participantAnswering,
              let questionPayload,
              let questionType = questionPayload.question.type else {
            return false
        }

        switch questionType {
        case .openEnded:
            return openAnswerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false

        case .singleChoice, .multiChoice:
            return selectedOptionIndexes.isEmpty == false
        }
    }

    private func makeAnswer(for question: QuizQuestionData) -> String? {
        guard let questionType = question.type else {
            return nil
        }

        switch questionType {
        case .openEnded:
            let normalizedText = openAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
            return normalizedText.isEmpty ? nil : normalizedText

        case .singleChoice:
            guard let selectedIndex = selectedOptionIndexes.first else { return nil }
            return String(selectedIndex)

        case .multiChoice:
            let sortedIndexes = selectedOptionIndexes.sorted()
            guard sortedIndexes.isEmpty == false,
                  let data = try? JSONSerialization.data(withJSONObject: sortedIndexes),
                  let jsonString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return jsonString
        }
    }

    private func calculateTimeSpentMs() -> Int64 {
        guard let questionDisplayedAt else { return 0 }
        return max(0, Int64(Date().timeIntervalSince(questionDisplayedAt) * 1000))
    }

    private func questionIdentity(for payload: QuizQuestionPayload?) -> String? {
        guard let payload else { return nil }
        return "\(payload.question.id ?? "none"):\(payload.questionIndex)"
    }

    private func normalizedQuizTitle(_ title: String?) -> String? {
        let normalizedTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedTitle.isEmpty ? nil : normalizedTitle
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

    private func handleKickedFromQuizIfNeeded(_ message: String) async -> Bool {
        guard isKickedError(message) else {
            return false
        }

        lastServerErrorAt = Date()
        hasRequestedFlowClose = true
        let cachedQuizTitle = await quizParticipationService.currentQuizTitle()
        let resolvedQuizTitle = quizTitle ?? cachedQuizTitle
        eventsTask?.cancel()
        eventsTask = nil
        await quizParticipationService.disconnect()
        await presenter.presentKickedFromQuiz(quizTitle: resolvedQuizTitle)
        return true
    }

    private func handleSessionReplacedIfNeeded(_ message: String) async -> Bool {
        guard isSessionReplacedError(message) else {
            return false
        }

        lastServerErrorAt = Date()
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

        if isCancelingQuiz || hasRequestedFlowClose {
            lastServerErrorAt = Date()
            return true
        }

        lastServerErrorAt = Date()
        hasRequestedFlowClose = true
        eventsTask?.cancel()
        eventsTask = nil
        await quizParticipationService.disconnect()
        await presenter.presentQuizDeletedByCreator()
        return true
    }

    private func isKickedError(_ message: String) -> Bool {
        let normalizedMessage = message
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return normalizedMessage == "you have been kicked"
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

        return ""
    }

    private func logQuizFlow(_ message: String) {
        #if DEBUG
        let timestamp = Self.logDateFormatter.string(from: Date())
        print("[QuizFlow][QuizParticipatingLogic][\(timestamp)] \(message)")
        #endif
    }
}

// MARK: - Models
private extension QuizParticipatingLogic {
    struct RankedParticipantRow {
        let participant: QuizParticipant
        let score: Int
        let isAnswered: Bool
        let isOffline: Bool
        let place: Int
    }

    struct NormalizedLeaderboardEntry {
        let user: QuizParticipant
        let rawRank: Int
        let displayRank: Int
        let score: Int
    }
}

// MARK: - Private Methods
private extension QuizParticipatingModels.Phase {
    var logDescription: String {
        switch self {
        case .participantAnswering:
            return "participantAnswering"
        case .participantSubmittedWaitingOthers:
            return "participantSubmittedWaitingOthers"
        case .participantWaitingForCreator:
            return "participantWaitingForCreator"
        case .creatorWaitingParticipants:
            return "creatorWaitingParticipants"
        case .creatorReadyToContinue:
            return "creatorReadyToContinue"
        case .quizFinished:
            return "quizFinished"
        }
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
