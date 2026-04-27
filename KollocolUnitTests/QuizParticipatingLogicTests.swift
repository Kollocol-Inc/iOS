//
//  QuizParticipatingLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizParticipatingLogicTests {
    @Test
    func leaveFlowPresentsConfirmationThenCloses() async {
        let presenter = QuizParticipatingPresenterSpy()
        let participationService = QuizParticipatingParticipationServiceMock()
        let logic = QuizParticipatingLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizParticipatingQuizServiceMock()
        )

        await logic.handleLeaveAttempt()
        await logic.handleLeaveTap()

        #expect(await presenter.leaveConfirmationCallsCount() == 1)
        #expect(await participationService.disconnectCallsCount() == 1)
        #expect(await presenter.closeFlowCallsCount() == 1)
    }

    @Test
    func singleChoiceOptionTapAndSubmitSendsAnswer() async {
        let presenter = QuizParticipatingPresenterSpy()
        let participationService = QuizParticipatingParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:user-1",
                quizType: .sync,
                quizStatus: .active,
                isCreator: false
            )
        )
        await participationService.setParticipants([
            makeParticipant(userId: "host", isCreator: true),
            makeParticipant(userId: "user-1", isCreator: false)
        ])
        await participationService.setQuestionPayload(
            makeQuestionPayload(
                id: "q-single",
                type: .singleChoice,
                options: ["A", "B", "C"]
            )
        )

        let logic = QuizParticipatingLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizParticipatingQuizServiceMock()
        )

        await logic.handleViewDidLoad()
        await logic.handleOptionTap(1)
        await logic.handleSubmitTap()

        let requests = await participationService.sendAnswerRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.questionId == "q-single")
        #expect(requests.first?.answer == "1")
        #expect((requests.first?.timeSpentMs ?? -1) >= 0)

        let state = await presenter.lastState()
        #expect(state?.phase == .participantSubmittedWaitingOthers)
        #expect(state?.isBottomButtonEnabled == false)
        #expect(state?.selectedOptionIndexes == [1])
    }

    @Test
    func openAnswerTextChangeThenSubmitSendsTrimmedAnswer() async {
        let presenter = QuizParticipatingPresenterSpy()
        let participationService = QuizParticipatingParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:user-2",
                quizType: .sync,
                quizStatus: .active,
                isCreator: false
            )
        )
        await participationService.setParticipants([
            makeParticipant(userId: "host", isCreator: true),
            makeParticipant(userId: "user-2", isCreator: false)
        ])
        await participationService.setQuestionPayload(
            makeQuestionPayload(
                id: "q-open",
                type: .openEnded,
                options: []
            )
        )

        let logic = QuizParticipatingLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizParticipatingQuizServiceMock()
        )

        await logic.handleViewDidLoad()
        await logic.handleOpenAnswerTextChanged("  hello world  ")

        let stateBeforeSubmit = await presenter.lastState()
        #expect(stateBeforeSubmit?.openAnswerText == "  hello world  ")
        #expect(stateBeforeSubmit?.isBottomButtonEnabled == true)

        await logic.handleSubmitTap()

        let requests = await participationService.sendAnswerRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.questionId == "q-open")
        #expect(requests.first?.answer == "hello world")
    }

    @Test
    func cancelQuizTapWhenNotCreatorDoesNothing() async {
        let presenter = QuizParticipatingPresenterSpy()
        let participationService = QuizParticipatingParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:user-3",
                quizType: .sync,
                quizStatus: .active,
                isCreator: false
            )
        )

        let quizService = QuizParticipatingQuizServiceMock()
        let logic = QuizParticipatingLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: quizService
        )

        await logic.handleViewDidLoad()
        await logic.handleCancelQuizTap()

        #expect(await quizService.deletedInstanceIDs().isEmpty)
        #expect(await presenter.serverErrors().isEmpty)
        #expect(await presenter.serviceErrors().isEmpty)
    }
}

private actor QuizParticipatingPresenterSpy: QuizParticipatingPresenter {
    private var quizTitlesStorage: [String] = []
    private var statesStorage: [QuizParticipatingModels.ViewState] = []
    private var serviceErrorsStorage: [QuizParticipationServiceError] = []
    private var serverErrorsStorage: [String] = []
    private var kickedFromQuizTitlesStorage: [String?] = []
    private var sessionReplacedCalls = 0
    private var quizDeletedByCreatorCalls = 0
    private var quizCanceledTitlesStorage: [String] = []
    private var leaveConfirmationCalls = 0
    private var closeFlowCalls = 0

    func presentQuizTitle(_ quizTitle: String) async {
        quizTitlesStorage.append(quizTitle)
    }

    func presentState(_ state: QuizParticipatingModels.ViewState) async {
        statesStorage.append(state)
    }

    func presentServiceError(_ error: QuizParticipationServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentServerError(message: String) async {
        serverErrorsStorage.append(message)
    }

    func presentKickedFromQuiz(quizTitle: String?) async {
        kickedFromQuizTitlesStorage.append(quizTitle)
    }

    func presentSessionReplaced() async {
        sessionReplacedCalls += 1
    }

    func presentQuizDeletedByCreator() async {
        quizDeletedByCreatorCalls += 1
    }

    func presentQuizCanceled(quizTitle: String) async {
        quizCanceledTitlesStorage.append(quizTitle)
    }

    func presentLeaveConfirmation() async {
        leaveConfirmationCalls += 1
    }

    func presentCloseFlow() async {
        closeFlowCalls += 1
    }

    func lastState() -> QuizParticipatingModels.ViewState? {
        statesStorage.last
    }

    func serviceErrors() -> [QuizParticipationServiceError] {
        serviceErrorsStorage
    }

    func serverErrors() -> [String] {
        serverErrorsStorage
    }

    func leaveConfirmationCallsCount() -> Int {
        leaveConfirmationCalls
    }

    func closeFlowCallsCount() -> Int {
        closeFlowCalls
    }
}

private actor QuizParticipatingParticipationServiceMock: QuizParticipationService {
    private var connectionState: QuizParticipationConnectionState = .disconnected
    private var connectedPayload: QuizConnectedPayload?
    private var quizTitle: String?
    private var participantsStorage: [QuizParticipant] = []
    private var questionPayload: QuizQuestionPayload?
    private var leaderboardPayload: QuizLeaderboardPayload?
    private var disconnectCalls = 0
    private var sendAnswerRequestsStorage: [(questionId: String, answer: String, timeSpentMs: Int64?)] = []

    func setConnectionState(_ state: QuizParticipationConnectionState) {
        connectionState = state
    }

    func setConnectedPayload(_ payload: QuizConnectedPayload?) {
        connectedPayload = payload
    }

    func setQuizTitle(_ title: String?) {
        quizTitle = title
    }

    func setParticipants(_ participants: [QuizParticipant]) {
        participantsStorage = participants
    }

    func setQuestionPayload(_ payload: QuizQuestionPayload?) {
        questionPayload = payload
    }

    func setLeaderboardPayload(_ payload: QuizLeaderboardPayload?) {
        leaderboardPayload = payload
    }

    func disconnectCallsCount() -> Int {
        disconnectCalls
    }

    func sendAnswerRequests() -> [(questionId: String, answer: String, timeSpentMs: Int64?)] {
        sendAnswerRequestsStorage
    }

    func connect(accessCode: String) async throws {
    }

    func disconnect() async {
        disconnectCalls += 1
    }

    func currentConnectionState() -> QuizParticipationConnectionState {
        connectionState
    }

    func currentConnectedPayload() -> QuizConnectedPayload? {
        connectedPayload
    }

    func currentQuizTitle() -> String? {
        quizTitle
    }

    func currentParticipantsCount() -> Int {
        max(1, participantsStorage.count)
    }

    func currentParticipants() -> [QuizParticipant] {
        participantsStorage
    }

    func currentQuestionPayload() -> QuizQuestionPayload? {
        questionPayload
    }

    func currentLeaderboardPayload() -> QuizLeaderboardPayload? {
        leaderboardPayload
    }

    func makeEventStream() -> AsyncStream<QuizParticipationEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func startQuiz() async throws {
    }

    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws {
        sendAnswerRequestsStorage.append((questionId, answer, timeSpentMs))
    }

    func kickParticipant(email: String) async throws {
    }

    func sendCommand(type: String) async throws {
    }

    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws {
    }
}

private actor QuizParticipatingQuizServiceMock: QuizService {
    private var hostingResult: [QuizInstance] = []
    private var deletedInstanceIDsStorage: [String] = []

    func setHostingResult(_ instances: [QuizInstance]) {
        hostingResult = instances
    }

    func deletedInstanceIDs() -> [String] {
        deletedInstanceIDsStorage
    }

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        []
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        []
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        hostingResult
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        hostingResult
    }

    func getTemplates() async throws -> [QuizTemplate] {
        []
    }

    func getTemplate(by templateId: String) async throws -> QuizTemplate {
        throw QuizServiceError.unknown
    }

    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws {
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {
    }

    func deleteTemplate(by templateId: String) async throws {
    }

    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String? {
        nil
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        throw QuizServiceError.unknown
    }

    func deleteQuizInstance(by instanceId: String) async throws {
        deletedInstanceIDsStorage.append(instanceId)
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        []
    }

    func getParticipantAnswers(instanceId: String, participantId: String) async throws -> QuizParticipantAnswersDetails {
        throw QuizServiceError.unknown
    }

    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws {
    }

    func reviewParticipantAnswer(
        instanceId: String,
        request: ReviewAnswerRequest
    ) async throws -> QuizAnswerReviewSuggestion {
        throw QuizServiceError.unknown
    }

    func publishQuizResults(instanceId: String) async throws {
    }
}

private func makeParticipant(userId: String, isCreator: Bool) -> QuizParticipant {
    QuizParticipant(
        userId: userId,
        firstName: userId,
        lastName: nil,
        email: "\(userId)@example.com",
        avatarURL: nil,
        isCreator: isCreator,
        isOnline: true
    )
}

private func makeQuestionPayload(
    id: String,
    type: QuestionType,
    options: [String]
) -> QuizQuestionPayload {
    QuizQuestionPayload(
        question: .init(
            id: id,
            text: "Question",
            type: type,
            options: options,
            orderIndex: 0,
            maxScore: 1,
            timeLimitSec: 30
        ),
        questionIndex: 0,
        totalQuestions: 1,
        timeLimitMs: 30_000,
        serverTime: 0
    )
}
