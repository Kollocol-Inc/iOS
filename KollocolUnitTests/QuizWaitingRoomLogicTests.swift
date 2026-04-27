//
//  QuizWaitingRoomLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizWaitingRoomLogicTests {
    @Test
    func viewDidLoadRoutesToParticipatingWhenQuizIsAlreadyActive() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:user-1",
                quizType: .sync,
                quizStatus: .active,
                isCreator: false
            )
        )

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleViewDidLoad()

        #expect(await presenter.routeToParticipatingCallsCount() == 1)
        #expect(await presenter.isCreatorPayloads().isEmpty)
        #expect(await presenter.participantsPayloads().isEmpty)
    }

    @Test
    func viewDidLoadPresentsWaitingRoomDataAndSortedParticipants() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:user-42",
                quizType: .sync,
                quizStatus: .waiting,
                isCreator: true
            )
        )
        await participationService.setQuizTitle("  Physics room  ")
        await participationService.setParticipants([
            makeParticipant(
                userId: "u2",
                firstName: "Bob",
                lastName: "Stone",
                email: "b@example.com",
                isCreator: false
            ),
            makeParticipant(
                userId: "host",
                firstName: "Teacher",
                lastName: "One",
                email: "host@example.com",
                isCreator: true
            ),
            makeParticipant(
                userId: "u1",
                firstName: "Alice",
                lastName: "Stone",
                email: "a@example.com",
                isCreator: false
            )
        ])

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleViewDidLoad()

        #expect(await presenter.isCreatorPayloads() == [true])
        #expect(await presenter.currentUserIDs() == ["user-42"])
        #expect(await presenter.quizTitles() == ["Physics room"])
        #expect(await presenter.participantsCounts() == [3])

        let participants = await presenter.lastParticipants()
        #expect(participants.count == 3)
        #expect(participants.first?.isCreator == true)
        #expect(participants[1].firstName == "Alice")
        #expect(participants[2].firstName == "Bob")
    }

    @Test
    func startQuizAsCreatorWithEnoughParticipantsCallsStart() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:host",
                quizType: .sync,
                quizStatus: .waiting,
                isCreator: true
            )
        )
        await participationService.setParticipants([
            makeParticipant(userId: "host", firstName: "Teacher", lastName: "One", email: "host@example.com", isCreator: true),
            makeParticipant(userId: "u1", firstName: "A", lastName: "B", email: "a@example.com", isCreator: false)
        ])

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleViewDidLoad()
        await logic.handleStartQuizTap()

        #expect(await participationService.startQuizCallsCount() == 1)
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func startQuizFailurePresentsServiceError() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:host",
                quizType: .sync,
                quizStatus: .waiting,
                isCreator: true
            )
        )
        await participationService.setParticipants([
            makeParticipant(userId: "host", firstName: "Teacher", lastName: "One", email: "host@example.com", isCreator: true),
            makeParticipant(userId: "u1", firstName: "A", lastName: "B", email: "a@example.com", isCreator: false)
        ])
        await participationService.setStartQuizError(.offline)

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleViewDidLoad()
        await logic.handleStartQuizTap()

        let errors = await presenter.serviceErrors()
        #expect(errors.count == 1)
        #expect(isQuizParticipationError(errors.first, .offline))
    }

    @Test
    func cancelQuizSuccessDeletesInstanceDisconnectsAndPresentsCanceled() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:host",
                quizType: .sync,
                quizStatus: .waiting,
                isCreator: true
            )
        )
        await participationService.setParticipants([
            makeParticipant(userId: "host", firstName: "Teacher", lastName: "One", email: "host@example.com", isCreator: true)
        ])
        await participationService.setQuizTitle("  Midterm  ")
        await participationService.setConnectionState(.connected(accessCode: "ROOM-1"))

        let quizService = QuizWaitingRoomQuizServiceMock()
        await quizService.setHostingResult([
            makeQuizInstance(id: "instance-1", accessCode: "ROOM-1", status: .waiting)
        ])

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: quizService,
            accessCode: "ROOM-1"
        )

        await logic.handleViewDidLoad()
        await logic.handleCancelQuizTap()

        #expect(await quizService.deletedInstanceIDs() == ["instance-1"])
        #expect(await participationService.disconnectCallsCount() == 1)
        #expect(await presenter.quizCanceledTitles() == ["Midterm"])
    }

    @Test
    func kickParticipantTapWithValidEmailPresentsConfirmation() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session:host",
                quizType: .sync,
                quizStatus: .waiting,
                isCreator: true
            )
        )

        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleViewDidLoad()
        await logic.handleKickParticipantTap(
            makeParticipant(
                userId: "u1",
                firstName: "Alex",
                lastName: "Doe",
                email: "  alex@example.com  ",
                isCreator: false
            )
        )

        #expect(await presenter.kickConfirmationsCount() == 1)
        #expect(await presenter.lastKickConfirmationEmail() == "alex@example.com")
        #expect(await presenter.lastKickConfirmationName() == "Alex Doe")
    }

    @Test
    func leaveFlowDisconnectsAndCloses() async {
        let presenter = QuizWaitingRoomPresenterSpy()
        let participationService = QuizWaitingRoomParticipationServiceMock()
        let logic = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: participationService,
            quizService: QuizWaitingRoomQuizServiceMock(),
            accessCode: "ROOM"
        )

        await logic.handleLeaveAttempt()
        await logic.handleLeaveTap()

        #expect(await presenter.leaveConfirmationCallsCount() == 1)
        #expect(await participationService.disconnectCallsCount() == 1)
        #expect(await presenter.closeFlowCallsCount() == 1)
    }
}

private actor QuizWaitingRoomPresenterSpy: QuizWaitingRoomPresenter {
    private var isCreatorStorage: [Bool] = []
    private var currentUserIDsStorage: [String?] = []
    private var quizTitlesStorage: [String] = []
    private var participantsCountsStorage: [Int] = []
    private var participantsStorage: [[QuizParticipant]] = []
    private var routeToParticipatingCalls = 0
    private var serviceErrorsStorage: [QuizParticipationServiceError] = []
    private var serverErrorsStorage: [String] = []
    private var kickConfirmationsStorage: [(name: String, email: String)] = []
    private var kickedFromQuizTitlesStorage: [String?] = []
    private var sessionReplacedCalls = 0
    private var quizDeletedByCreatorCalls = 0
    private var quizCanceledTitlesStorage: [String] = []
    private var leaveConfirmationCalls = 0
    private var closeFlowCalls = 0

    func presentIsCreator(_ isCreator: Bool) async {
        isCreatorStorage.append(isCreator)
    }

    func presentCurrentUserID(_ userID: String?) async {
        currentUserIDsStorage.append(userID)
    }

    func presentQuizTitle(_ quizTitle: String) async {
        quizTitlesStorage.append(quizTitle)
    }

    func presentParticipantsCount(_ count: Int) async {
        participantsCountsStorage.append(count)
    }

    func presentParticipants(_ participants: [QuizParticipant]) async {
        participantsStorage.append(participants)
    }

    func presentRouteToQuizParticipating() async {
        routeToParticipatingCalls += 1
    }

    func presentServiceError(_ error: QuizParticipationServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentServerError(message: String) async {
        serverErrorsStorage.append(message)
    }

    func presentKickParticipantConfirmation(participantName: String, participantEmail: String) async {
        kickConfirmationsStorage.append((participantName, participantEmail))
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

    func isCreatorPayloads() -> [Bool] {
        isCreatorStorage
    }

    func currentUserIDs() -> [String?] {
        currentUserIDsStorage
    }

    func quizTitles() -> [String] {
        quizTitlesStorage
    }

    func participantsCounts() -> [Int] {
        participantsCountsStorage
    }

    func participantsPayloads() -> [[QuizParticipant]] {
        participantsStorage
    }

    func lastParticipants() -> [QuizParticipant] {
        participantsStorage.last ?? []
    }

    func routeToParticipatingCallsCount() -> Int {
        routeToParticipatingCalls
    }

    func serviceErrors() -> [QuizParticipationServiceError] {
        serviceErrorsStorage
    }

    func kickConfirmationsCount() -> Int {
        kickConfirmationsStorage.count
    }

    func lastKickConfirmationEmail() -> String? {
        kickConfirmationsStorage.last?.email
    }

    func lastKickConfirmationName() -> String? {
        kickConfirmationsStorage.last?.name
    }

    func quizCanceledTitles() -> [String] {
        quizCanceledTitlesStorage
    }

    func leaveConfirmationCallsCount() -> Int {
        leaveConfirmationCalls
    }

    func closeFlowCallsCount() -> Int {
        closeFlowCalls
    }
}

private actor QuizWaitingRoomParticipationServiceMock: QuizParticipationService {
    private var connectionState: QuizParticipationConnectionState = .disconnected
    private var connectedPayload: QuizConnectedPayload?
    private var quizTitle: String?
    private var participantsStorage: [QuizParticipant] = []
    private var questionPayload: QuizQuestionPayload?
    private var leaderboardPayload: QuizLeaderboardPayload?
    private var disconnectCalls = 0
    private var startQuizCalls = 0
    private var startQuizError: QuizParticipationServiceError?
    private var kickRequestsStorage: [String] = []
    private var kickError: QuizParticipationServiceError?

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

    func setStartQuizError(_ error: QuizParticipationServiceError?) {
        startQuizError = error
    }

    func setKickError(_ error: QuizParticipationServiceError?) {
        kickError = error
    }

    func disconnectCallsCount() -> Int {
        disconnectCalls
    }

    func startQuizCallsCount() -> Int {
        startQuizCalls
    }

    func kickRequests() -> [String] {
        kickRequestsStorage
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
        startQuizCalls += 1
        if let startQuizError {
            throw startQuizError
        }
    }

    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws {
    }

    func kickParticipant(email: String) async throws {
        kickRequestsStorage.append(email)
        if let kickError {
            throw kickError
        }
    }

    func sendCommand(type: String) async throws {
    }

    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws {
    }
}

private actor QuizWaitingRoomQuizServiceMock: QuizService {
    private var hostingResult: [QuizInstance] = []
    private var hostingError: QuizServiceError?
    private var deletedInstanceIDsStorage: [String] = []

    func setHostingResult(_ hosting: [QuizInstance]) {
        hostingResult = hosting
    }

    func setHostingError(_ error: QuizServiceError?) {
        hostingError = error
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
        try await getHostingQuizzes(status: nil)
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        if let hostingError {
            throw hostingError
        }
        return hostingResult
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

    func reviewParticipantAnswer(instanceId: String, request: ReviewAnswerRequest) async throws -> QuizAnswerReviewSuggestion {
        throw QuizServiceError.unknown
    }

    func publishQuizResults(instanceId: String) async throws {
    }
}

private func makeParticipant(
    userId: String,
    firstName: String,
    lastName: String,
    email: String,
    isCreator: Bool
) -> QuizParticipant {
    QuizParticipant(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        email: email,
        avatarURL: nil,
        isCreator: isCreator,
        isOnline: true
    )
}

private func makeQuizInstance(
    id: String,
    accessCode: String,
    status: QuizStatus
) -> QuizInstance {
    QuizInstance(
        accessCode: accessCode,
        createdAt: nil,
        deadline: nil,
        groupId: nil,
        hostUserId: nil,
        id: id,
        quizType: .sync,
        settings: nil,
        status: status,
        templateId: nil,
        title: "Quiz",
        totalQuestions: nil,
        totalTime: nil
    )
}

private func isQuizParticipationError(
    _ actual: QuizParticipationServiceError?,
    _ expected: QuizParticipationServiceError
) -> Bool {
    switch (actual, expected) {
    case (.unauthorized, .unauthorized),
            (.invalidConfiguration, .invalidConfiguration),
            (.invalidCode, .invalidCode),
            (.quizAlreadyStarted, .quizAlreadyStarted),
            (.quizAlreadyFinished, .quizAlreadyFinished),
            (.offline, .offline),
            (.notConnected, .notConnected),
            (.connectionClosed, .connectionClosed),
            (.connectionTimeout, .connectionTimeout),
            (.encodingFailed, .encodingFailed),
            (.unknown, .unknown):
        return true
    default:
        return false
    }
}
