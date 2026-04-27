//
//  StartQuizLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct StartQuizLogicTests {
    @Test
    func handleBackTapPresentsCloseScreen() async {
        let presenter = StartQuizPresenterSpy()
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: StartQuizQuizServiceMock(),
            quizParticipationService: StartQuizParticipationServiceMock(),
            template: makeTemplate(quizType: .sync)
        )

        await logic.handleBackTap()

        #expect(await presenter.closeScreenCallsCount() == 1)
    }

    @Test
    func startAsyncQuizSuccessPresentsGenericSuccess() async {
        let presenter = StartQuizPresenterSpy()
        let quizService = StartQuizQuizServiceMock()
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            quizParticipationService: StartQuizParticipationServiceMock(),
            template: makeTemplate(quizType: .async)
        )
        let deadline = Date(timeIntervalSince1970: 1_800_000_000)

        await logic.startQuiz(formData: .init(title: "  Async Quiz  ", deadline: deadline))

        #expect(await presenter.loadingStates() == [true, false])
        #expect(await presenter.startQuizSuccessCallsCount() == 1)
        #expect(await presenter.startSyncQuizSuccessCodes().isEmpty)
        #expect(await presenter.joinQuizErrors().isEmpty)

        let request = await quizService.lastCreateInstanceRequest()
        #expect(request?.title == "Async Quiz")
        #expect(request?.deadline == deadline)
    }

    @Test
    func startSyncQuizWithMissingAccessCodePresentsUnknownServiceError() async {
        let presenter = StartQuizPresenterSpy()
        let quizService = StartQuizQuizServiceMock()
        await quizService.setCreateQuizInstanceResult("   ")
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            quizParticipationService: StartQuizParticipationServiceMock(),
            template: makeTemplate(quizType: .sync)
        )

        await logic.startQuiz(formData: .init(title: " Sync ", deadline: Date()))

        #expect(await presenter.loadingStates() == [true, false])
        let serviceErrors = await presenter.serviceErrors()
        #expect(serviceErrors.count == 1)
        #expect(isQuizServiceError(serviceErrors.first, .unknown))
        #expect(await presenter.startSyncQuizSuccessCodes().isEmpty)
    }

    @Test
    func startSyncQuizConnectSuccessPresentsSyncSuccess() async {
        let presenter = StartQuizPresenterSpy()
        let quizService = StartQuizQuizServiceMock()
        await quizService.setCreateQuizInstanceResult(" CODE42 ")
        let participationService = StartQuizParticipationServiceMock()
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            quizParticipationService: participationService,
            template: makeTemplate(quizType: .sync)
        )

        await logic.startQuiz(formData: .init(title: "  ", deadline: Date()))

        #expect(await presenter.loadingStates() == [true, false])
        #expect(await participationService.connectRequests() == ["CODE42"])
        #expect(await presenter.startSyncQuizSuccessCodes() == ["CODE42"])

        let request = await quizService.lastCreateInstanceRequest()
        #expect(request?.title == nil)
        #expect(request?.deadline == nil)
    }

    @Test
    func startSyncQuizConnectFailurePresentsJoinError() async {
        let presenter = StartQuizPresenterSpy()
        let quizService = StartQuizQuizServiceMock()
        await quizService.setCreateQuizInstanceResult("ROOM")
        let participationService = StartQuizParticipationServiceMock()
        await participationService.setConnectError(.connectionTimeout)
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            quizParticipationService: participationService,
            template: makeTemplate(quizType: .sync)
        )

        await logic.startQuiz(formData: .init(title: "Quiz", deadline: nil))

        let errors = await presenter.joinQuizErrors()
        #expect(errors.count == 1)
        #expect(isQuizParticipationError(errors.first, .connectionTimeout))
        #expect(await presenter.startSyncQuizSuccessCodes().isEmpty)
    }

    @Test
    func startQuizCreateFailurePresentsServiceError() async {
        let presenter = StartQuizPresenterSpy()
        let quizService = StartQuizQuizServiceMock()
        await quizService.setCreateQuizInstanceError(.server)
        let logic = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            quizParticipationService: StartQuizParticipationServiceMock(),
            template: makeTemplate(quizType: .async)
        )

        await logic.startQuiz(formData: .init(title: "Quiz", deadline: nil))

        let serviceErrors = await presenter.serviceErrors()
        #expect(serviceErrors.count == 1)
        #expect(isQuizServiceError(serviceErrors.first, .server))
        #expect(await presenter.loadingStates() == [true, false])
    }
}

private actor StartQuizPresenterSpy: StartQuizPresenter {
    private var loadingStatesStorage: [Bool] = []
    private var startQuizSuccessCalls = 0
    private var startSyncQuizSuccessCodesStorage: [String] = []
    private var serviceErrorsStorage: [QuizServiceError] = []
    private var joinQuizErrorsStorage: [QuizParticipationServiceError] = []
    private var closeScreenCalls = 0

    func presentStartQuizLoading(_ isLoading: Bool) async {
        loadingStatesStorage.append(isLoading)
    }

    func presentStartQuizSuccess() async {
        startQuizSuccessCalls += 1
    }

    func presentStartSyncQuizSuccess(accessCode: String) async {
        startSyncQuizSuccessCodesStorage.append(accessCode)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        joinQuizErrorsStorage.append(error)
    }

    func presentCloseScreen() async {
        closeScreenCalls += 1
    }

    func loadingStates() -> [Bool] {
        loadingStatesStorage
    }

    func startQuizSuccessCallsCount() -> Int {
        startQuizSuccessCalls
    }

    func startSyncQuizSuccessCodes() -> [String] {
        startSyncQuizSuccessCodesStorage
    }

    func serviceErrors() -> [QuizServiceError] {
        serviceErrorsStorage
    }

    func joinQuizErrors() -> [QuizParticipationServiceError] {
        joinQuizErrorsStorage
    }

    func closeScreenCallsCount() -> Int {
        closeScreenCalls
    }
}

private actor StartQuizQuizServiceMock: QuizService {
    private var createQuizInstanceResult: String?
    private var createQuizInstanceError: QuizServiceError?
    private var createQuizInstanceRequestsStorage: [CreateInstanceRequest] = []

    func setCreateQuizInstanceResult(_ value: String?) {
        createQuizInstanceResult = value
    }

    func setCreateQuizInstanceError(_ value: QuizServiceError?) {
        createQuizInstanceError = value
    }

    func lastCreateInstanceRequest() -> CreateInstanceRequest? {
        createQuizInstanceRequestsStorage.last
    }

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        []
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        []
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        []
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        []
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
        createQuizInstanceRequestsStorage.append(request)
        if let createQuizInstanceError {
            throw createQuizInstanceError
        }
        return createQuizInstanceResult
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        throw QuizServiceError.unknown
    }

    func deleteQuizInstance(by instanceId: String) async throws {
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

private actor StartQuizParticipationServiceMock: QuizParticipationService {
    private var connectRequestsStorage: [String] = []
    private var connectError: QuizParticipationServiceError?

    func setConnectError(_ error: QuizParticipationServiceError?) {
        connectError = error
    }

    func connectRequests() -> [String] {
        connectRequestsStorage
    }

    func connect(accessCode: String) async throws {
        connectRequestsStorage.append(accessCode)
        if let connectError {
            throw connectError
        }
    }

    func disconnect() async {
    }

    func currentConnectionState() -> QuizParticipationConnectionState {
        .disconnected
    }

    func currentConnectedPayload() -> QuizConnectedPayload? {
        nil
    }

    func currentQuizTitle() -> String? {
        nil
    }

    func currentParticipantsCount() -> Int {
        1
    }

    func currentParticipants() -> [QuizParticipant] {
        []
    }

    func currentQuestionPayload() -> QuizQuestionPayload? {
        nil
    }

    func currentLeaderboardPayload() -> QuizLeaderboardPayload? {
        nil
    }

    func makeEventStream() -> AsyncStream<QuizParticipationEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func startQuiz() async throws {
    }

    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws {
    }

    func kickParticipant(email: String) async throws {
    }

    func sendCommand(type: String) async throws {
    }

    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws {
    }
}

private func makeTemplate(quizType: QuizType) -> QuizTemplate {
    QuizTemplate(
        createdAt: nil,
        description: nil,
        id: "template-id",
        questions: nil,
        quizType: quizType,
        settings: nil,
        title: nil,
        updatedAt: nil,
        userId: nil
    )
}

private func isQuizServiceError(_ actual: QuizServiceError?, _ expected: QuizServiceError) -> Bool {
    switch (actual, expected) {
    case (.badRequest, .badRequest),
            (.tooManyRequests, .tooManyRequests),
            (.unauthorized, .unauthorized),
            (.offline, .offline),
            (.server, .server),
            (.unknown, .unknown):
        return true
    default:
        return false
    }
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
