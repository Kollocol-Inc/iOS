//
//  MyQuizzesLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct MyQuizzesLogicTests {
    @Test
    func fetchHostingQuizzesSuccessPresentsHostingList() async {
        let presenter = MyQuizzesPresenterSpy()
        let quizService = MyQuizzesQuizServiceMock()
        await quizService.setHostingResult([
            makeQuizInstance(id: "h1", title: "First", accessCode: "A1", quizType: .sync),
            makeQuizInstance(id: "h2", title: "Second", accessCode: "A2", quizType: .async)
        ])

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.fetchHostingQuizzes()

        #expect(await presenter.hostingPayloadsCount() == 1)
        #expect(await presenter.lastHostingIDs() == ["h1", "h2"])
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func fetchTemplatesEmptyPresentsEmptyState() async {
        let presenter = MyQuizzesPresenterSpy()
        let quizService = MyQuizzesQuizServiceMock()
        await quizService.setTemplatesResult([])

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.fetchTemplates()

        #expect(await presenter.templatesPayloadsCount() == 1)
        #expect(await presenter.lastTemplateIDs().isEmpty)
        #expect(await presenter.lastTemplateEmptyStateText() != nil)
    }

    @Test
    func joinQuizFailurePresentsJoinError() async {
        let presenter = MyQuizzesPresenterSpy()
        let participationService = MyQuizzesParticipationServiceMock()
        await participationService.setConnectError(.invalidCode)

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: MyQuizzesQuizServiceMock(),
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: participationService
        )

        await logic.joinQuiz(code: "WRONG")

        let errors = await presenter.joinErrors()
        #expect(errors.count == 1)
        #expect(isQuizParticipationError(errors.first, .invalidCode))
    }

    @Test
    func generateTemplateTrimsPromptAndReturnsResult() async throws {
        let mlService = MyQuizzesMLServiceMock()
        await mlService.setGenerateTemplateResult(
            GeneratedTemplate(
                title: "Generated",
                questions: [makeQuestion(id: "q1")]
            )
        )

        let logic = MyQuizzesLogic(
            presenter: MyQuizzesPresenterSpy(),
            quizService: MyQuizzesQuizServiceMock(),
            mlService: mlService,
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        let generated = try await logic.generateTemplate(prompt: "  Build me a quiz  ")

        #expect(generated.title == "Generated")
        #expect(generated.questions.count == 1)
        #expect(await mlService.generateTemplateRequests() == ["Build me a quiz"])
    }

    @Test
    func generateTemplateWithEmptyPromptThrowsBadRequest() async {
        let logic = MyQuizzesLogic(
            presenter: MyQuizzesPresenterSpy(),
            quizService: MyQuizzesQuizServiceMock(),
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        do {
            _ = try await logic.generateTemplate(prompt: "   ")
            Issue.record("Expected MLServiceError.badRequest")
        } catch let error as MLServiceError {
            #expect(error == .badRequest)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func handleHostingQuizTapActiveAsyncRoutesParticipantsOverview() async {
        let presenter = MyQuizzesPresenterSpy()
        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: MyQuizzesQuizServiceMock(),
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.handleHostingQuizTap(
            makeQuizViewData(
                id: "  instance-7  ",
                title: " Async Quiz ",
                accessCode: "ROOM",
                quizType: .async,
                status: .active
            ),
            section: .active
        )

        #expect(await presenter.participantsOverviewCallsCount() == 1)
        #expect(await presenter.lastParticipantsOverviewInstanceID() == "instance-7")
        #expect(await presenter.lastParticipantsOverviewMode() == .asyncState)
    }

    @Test
    func handleHostingQuizTapPendingReviewRoutesReviewMode() async {
        let presenter = MyQuizzesPresenterSpy()
        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: MyQuizzesQuizServiceMock(),
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.handleHostingQuizTap(
            makeQuizViewData(
                id: "review-1",
                title: "Review quiz",
                accessCode: nil,
                quizType: .sync,
                status: .pendingReview
            ),
            section: .pendingReview
        )

        #expect(await presenter.participantsOverviewCallsCount() == 1)
        #expect(await presenter.lastParticipantsOverviewInstanceID() == "review-1")
        #expect(await presenter.lastParticipantsOverviewMode() == .review)
    }

    @Test
    func routeToStartQuizScreenUsesLoadedTemplate() async {
        let presenter = MyQuizzesPresenterSpy()
        let quizService = MyQuizzesQuizServiceMock()
        await quizService.setTemplatesResult([
            makeTemplate(id: "template-1", title: "Template")
        ])

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.fetchTemplates()
        await logic.routeToStartQuizScreen(templateId: "template-1")

        #expect(await presenter.startQuizTemplateIDs() == ["template-1"])
    }

    @Test
    func deleteTemplateRemovesFromLocalListAndRepresentsTemplates() async {
        let presenter = MyQuizzesPresenterSpy()
        let quizService = MyQuizzesQuizServiceMock()
        await quizService.setTemplatesResult([
            makeTemplate(id: "t1", title: "B-template"),
            makeTemplate(id: "t2", title: "A-template")
        ])

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.fetchTemplates()
        await logic.deleteTemplate(templateId: "t1")

        #expect(await quizService.deletedTemplateIDs() == ["t1"])
        #expect(await presenter.lastTemplateIDs() == ["t2"])
    }

    @Test
    func handleTemplateTapAndQuizTypeTapForwardToPresenter() async {
        let presenter = MyQuizzesPresenterSpy()
        let quizService = MyQuizzesQuizServiceMock()
        await quizService.setTemplatesResult([
            makeTemplate(id: "tpl-1", title: "Template 1")
        ])

        let logic = MyQuizzesLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: MyQuizzesMLServiceMock(),
            quizParticipationService: MyQuizzesParticipationServiceMock()
        )

        await logic.fetchTemplates()
        await logic.handleTemplateTap(templateId: "tpl-1")
        await logic.handleQuizTypeTap(.sync)

        #expect(await presenter.templateEditingIDs() == ["tpl-1"])
        #expect(await presenter.quizTypeInfoRequests() == [.sync])
    }
}

private actor MyQuizzesPresenterSpy: MyQuizzesPresenter {
    private var hostingPayloadIDsStorage: [[String?]] = []
    private var templatesPayloadIDsStorage: [[String?]] = []
    private var templatesEmptyStateTextsStorage: [String?] = []
    private var serviceErrorsStorage: [QuizServiceError] = []
    private var templateGenerationErrorsStorage: [MLServiceError] = []
    private var createTemplateScreenCalls = 0
    private var createTemplateFromTitlesStorage: [String?] = []
    private var participantsOverviewStorage: [QuizParticipantsOverviewModels.InitialData] = []
    private var startQuizTemplateIDsStorage: [String?] = []
    private var templateEditingIDsStorage: [String?] = []
    private var joinSuccessCodesStorage: [String] = []
    private var joinErrorsStorage: [QuizParticipationServiceError] = []
    private var joinConfirmationsStorage: [(accessCode: String, quizTitle: String)] = []
    private var quizTypeInfoRequestsStorage: [QuizType] = []

    func presentHostingQuizzes(_ hosting: [QuizInstance]) async {
        hostingPayloadIDsStorage.append(hosting.map(\.id))
    }

    func presentTemplates(_ templates: [QuizTemplate], emptyStateText: String?) async {
        templatesPayloadIDsStorage.append(templates.map(\.id))
        templatesEmptyStateTextsStorage.append(emptyStateText)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentTemplateGenerationError(_ error: MLServiceError) async {
        templateGenerationErrorsStorage.append(error)
    }

    func presentCreateTemplateScreen() async {
        createTemplateScreenCalls += 1
    }

    func presentCreateTemplateScreen(from generatedTemplate: GeneratedTemplate) async {
        createTemplateFromTitlesStorage.append(generatedTemplate.title)
    }

    func presentQuizParticipantsOverview(_ initialData: QuizParticipantsOverviewModels.InitialData) async {
        participantsOverviewStorage.append(initialData)
    }

    func presentStartQuizScreen(template: QuizTemplate) async {
        startQuizTemplateIDsStorage.append(template.id)
    }

    func presentTemplateEditingScreen(_ template: QuizTemplate) async {
        templateEditingIDsStorage.append(template.id)
    }

    func presentJoinQuizSuccess(accessCode: String) async {
        joinSuccessCodesStorage.append(accessCode)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        joinErrorsStorage.append(error)
    }

    func presentJoinQuizConfirmation(accessCode: String, quizTitle: String) async {
        joinConfirmationsStorage.append((accessCode, quizTitle))
    }

    func presentQuizTypeInfo(_ quizType: QuizType) async {
        quizTypeInfoRequestsStorage.append(quizType)
    }

    func hostingPayloadsCount() -> Int {
        hostingPayloadIDsStorage.count
    }

    func lastHostingIDs() -> [String?] {
        hostingPayloadIDsStorage.last ?? []
    }

    func templatesPayloadsCount() -> Int {
        templatesPayloadIDsStorage.count
    }

    func lastTemplateIDs() -> [String?] {
        templatesPayloadIDsStorage.last ?? []
    }

    func lastTemplateEmptyStateText() -> String? {
        templatesEmptyStateTextsStorage.last ?? nil
    }

    func serviceErrors() -> [QuizServiceError] {
        serviceErrorsStorage
    }

    func participantsOverviewCallsCount() -> Int {
        participantsOverviewStorage.count
    }

    func lastParticipantsOverviewInstanceID() -> String? {
        participantsOverviewStorage.last?.instanceId
    }

    func lastParticipantsOverviewMode() -> QuizParticipantsOverviewModels.Mode? {
        participantsOverviewStorage.last?.mode
    }

    func startQuizTemplateIDs() -> [String?] {
        startQuizTemplateIDsStorage
    }

    func templateEditingIDs() -> [String?] {
        templateEditingIDsStorage
    }

    func joinErrors() -> [QuizParticipationServiceError] {
        joinErrorsStorage
    }

    func quizTypeInfoRequests() -> [QuizType] {
        quizTypeInfoRequestsStorage
    }
}

private actor MyQuizzesQuizServiceMock: QuizService {
    private var hostingResult: [QuizInstance] = []
    private var templatesResult: [QuizTemplate] = []
    private var hostingError: QuizServiceError?
    private var templatesError: QuizServiceError?
    private var deleteTemplateError: QuizServiceError?
    private var deletedTemplateIDsStorage: [String] = []

    func setHostingResult(_ quizzes: [QuizInstance]) {
        hostingResult = quizzes
    }

    func setTemplatesResult(_ templates: [QuizTemplate]) {
        templatesResult = templates
    }

    func setHostingError(_ error: QuizServiceError?) {
        hostingError = error
    }

    func setTemplatesError(_ error: QuizServiceError?) {
        templatesError = error
    }

    func setDeleteTemplateError(_ error: QuizServiceError?) {
        deleteTemplateError = error
    }

    func deletedTemplateIDs() -> [String] {
        deletedTemplateIDsStorage
    }

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        []
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        []
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        if let hostingError {
            throw hostingError
        }
        return hostingResult
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        try await getHostingQuizzes()
    }

    func getTemplates() async throws -> [QuizTemplate] {
        if let templatesError {
            throw templatesError
        }
        return templatesResult
    }

    func getTemplate(by templateId: String) async throws -> QuizTemplate {
        throw QuizServiceError.unknown
    }

    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws {
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {
    }

    func deleteTemplate(by templateId: String) async throws {
        deletedTemplateIDsStorage.append(templateId)
        if let deleteTemplateError {
            throw deleteTemplateError
        }
    }

    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String? {
        nil
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

private actor MyQuizzesMLServiceMock: MLService {
    private var generateTemplateResult = GeneratedTemplate(title: nil, questions: [])
    private var generateTemplateError: MLServiceError?
    private var generateTemplateRequestsStorage: [GenerateTemplateMLRequest] = []

    func setGenerateTemplateResult(_ result: GeneratedTemplate) {
        generateTemplateResult = result
    }

    func setGenerateTemplateError(_ error: MLServiceError?) {
        generateTemplateError = error
    }

    func generateTemplateRequests() -> [String] {
        generateTemplateRequestsStorage.map(\.text)
    }

    func generateTemplate(_ request: GenerateTemplateMLRequest) async throws -> GeneratedTemplate {
        generateTemplateRequestsStorage.append(request)
        if let generateTemplateError {
            throw generateTemplateError
        }
        return generateTemplateResult
    }

    func generateTemplateQuestions(_ request: GenerateTemplateQuestionsMLRequest) async throws -> GeneratedQuestions {
        throw MLServiceError.unknown
    }

    func paraphrase(_ request: ParaphraseMLRequest) async throws -> ParaphrasedText {
        throw MLServiceError.unknown
    }
}

private actor MyQuizzesParticipationServiceMock: QuizParticipationService {
    private var connectError: QuizParticipationServiceError?

    func setConnectError(_ error: QuizParticipationServiceError?) {
        connectError = error
    }

    func connect(accessCode: String) async throws {
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

private func makeQuizInstance(
    id: String,
    title: String,
    accessCode: String?,
    quizType: QuizType,
    status: QuizStatus = .active
) -> QuizInstance {
    QuizInstance(
        accessCode: accessCode,
        createdAt: nil,
        deadline: nil,
        groupId: nil,
        hostUserId: nil,
        id: id,
        quizType: quizType,
        settings: nil,
        status: status,
        templateId: nil,
        title: title,
        totalQuestions: nil,
        totalTime: nil
    )
}

private func makeTemplate(id: String, title: String) -> QuizTemplate {
    QuizTemplate(
        createdAt: nil,
        description: "description",
        id: id,
        questions: [makeQuestion(id: "q")],
        quizType: .sync,
        settings: nil,
        title: title,
        updatedAt: nil,
        userId: nil
    )
}

private func makeQuestion(id: String) -> Question {
    Question(
        correctAnswer: .singleChoice(0),
        id: id,
        maxScore: 1,
        options: ["A"],
        text: "Question",
        timeLimitSec: 30,
        type: .singleChoice
    )
}

private func makeQuizViewData(
    id: String,
    title: String,
    accessCode: String?,
    quizType: QuizType,
    status: QuizStatus?
) -> QuizInstanceViewData {
    QuizInstanceViewData(
        accessCode: accessCode,
        deadline: nil,
        id: id,
        quizType: quizType,
        status: status,
        title: title,
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
