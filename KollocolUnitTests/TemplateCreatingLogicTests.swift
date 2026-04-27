//
//  TemplateCreatingLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct TemplateCreatingLogicTests {
    @Test
    func createTemplateSuccessBuildsRequestAndPresentsSuccess() async {
        let presenter = TemplateCreatingPresenterSpy()
        let quizService = TemplateCreatingQuizServiceMock()
        let logic = TemplateCreatingLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: TemplateCreatingMLServiceMock()
        )
        let questions = [makeQuestion(id: "q1", type: .singleChoice)]
        let formData = TemplateCreatingModels.FormData(
            title: "  Algebra  ",
            quizType: .sync,
            isRandomOrderEnabled: true,
            questions: questions
        )

        await logic.createTemplate(formData: formData)

        #expect(await presenter.loadingStates() == [true, false])
        #expect(await presenter.createSuccessCallsCount() == 1)
        #expect(await presenter.serviceErrors().isEmpty)

        let request = await quizService.lastCreateTemplateRequest()
        #expect(request?.title == "Algebra")
        #expect(request?.quizType == .sync)
        #expect(request?.questions?.count == 1)
        #expect(request?.settings?.randomOrder == true)
    }

    @Test
    func createTemplateFailurePresentsServiceError() async {
        let presenter = TemplateCreatingPresenterSpy()
        let quizService = TemplateCreatingQuizServiceMock()
        await quizService.setCreateTemplateError(.server)
        let logic = TemplateCreatingLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: TemplateCreatingMLServiceMock()
        )

        await logic.createTemplate(
            formData: .init(
                title: nil,
                quizType: .sync,
                isRandomOrderEnabled: false,
                questions: []
            )
        )

        #expect(await presenter.loadingStates() == [true, false])
        let errors = await presenter.serviceErrors()
        #expect(errors.count == 1)
        #expect(isQuizServiceError(errors.first, .server))
        #expect(await presenter.createSuccessCallsCount() == 0)
    }

    @Test
    func updateTemplateSuccessUsesTemplateIdAndRequest() async {
        let presenter = TemplateCreatingPresenterSpy()
        let quizService = TemplateCreatingQuizServiceMock()
        let logic = TemplateCreatingLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: TemplateCreatingMLServiceMock()
        )

        await logic.updateTemplate(
            by: "template-42",
            formData: .init(
                title: "  ",
                quizType: .async,
                isRandomOrderEnabled: false,
                questions: []
            )
        )

        #expect(await presenter.loadingStates() == [true, false])
        #expect(await presenter.createSuccessCallsCount() == 1)
        #expect(await quizService.lastUpdatedTemplateID() == "template-42")
        let request = await quizService.lastUpdateTemplateRequest()
        #expect(request?.title == nil)
        #expect(request?.quizType == .async)
        #expect(request?.questions == nil)
        #expect(request?.settings?.randomOrder == false)
    }

    @Test
    func deleteTemplateSuccessPresentsDeleteSuccess() async {
        let presenter = TemplateCreatingPresenterSpy()
        let quizService = TemplateCreatingQuizServiceMock()
        let logic = TemplateCreatingLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: TemplateCreatingMLServiceMock()
        )

        await logic.deleteTemplate(by: "template-id")

        #expect(await presenter.loadingStates() == [true, false])
        #expect(await presenter.deleteSuccessCallsCount() == 1)
        #expect(await quizService.deletedTemplateIDs() == ["template-id"])
    }

    @Test
    func paraphraseEmptyTextReturnsTrimmedInputWithoutServiceCall() async throws {
        let mlService = TemplateCreatingMLServiceMock()
        let logic = TemplateCreatingLogic(
            presenter: TemplateCreatingPresenterSpy(),
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: mlService
        )

        let result = try await logic.paraphraseQuestionText("   ")

        #expect(result == "")
        #expect(await mlService.paraphraseRequests().isEmpty)
    }

    @Test
    func paraphraseReturnsOriginalWhenModelOutputIsEmpty() async throws {
        let mlService = TemplateCreatingMLServiceMock()
        await mlService.setParaphraseResult(.init(text: "   "))
        let logic = TemplateCreatingLogic(
            presenter: TemplateCreatingPresenterSpy(),
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: mlService
        )

        let result = try await logic.paraphraseQuestionText("  Original text ")

        #expect(result == "Original text")
        #expect(await mlService.paraphraseRequests().map(\.text) == ["Original text"])
    }

    @Test
    func paraphraseFailureWrapsError() async {
        let mlService = TemplateCreatingMLServiceMock()
        await mlService.setParaphraseError(.tooManyRequests)
        let logic = TemplateCreatingLogic(
            presenter: TemplateCreatingPresenterSpy(),
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: mlService
        )

        await #expect(throws: MLServiceError.self) {
            try await logic.paraphraseQuestionText("Question")
        }
    }

    @Test
    func generateTemplateQuestionsBuildsRequestAndReturnsResponse() async throws {
        let mlService = TemplateCreatingMLServiceMock()
        let generated = [makeQuestion(id: "generated", type: .openEnded)]
        await mlService.setGenerateQuestionsResult(.init(questions: generated))
        let logic = TemplateCreatingLogic(
            presenter: TemplateCreatingPresenterSpy(),
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: mlService
        )

        let response = try await logic.generateTemplateQuestions(
            title: "  Geometry ",
            questions: []
        )

        #expect(response.count == 1)
        #expect(response.first?.id == "generated")

        let requests = await mlService.generateQuestionsRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.text == "Geometry")
        #expect(requests.first?.questions == nil)
    }

    @Test
    func generateTemplateQuestionsFailureWrapsError() async {
        let mlService = TemplateCreatingMLServiceMock()
        await mlService.setGenerateQuestionsError(.offline)
        let logic = TemplateCreatingLogic(
            presenter: TemplateCreatingPresenterSpy(),
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: mlService
        )

        await #expect(throws: MLServiceError.self) {
            _ = try await logic.generateTemplateQuestions(title: nil, questions: [])
        }
    }

    @Test
    func handleQuizTypeInfoTapForwardsToPresenter() async {
        let presenter = TemplateCreatingPresenterSpy()
        let logic = TemplateCreatingLogic(
            presenter: presenter,
            quizService: TemplateCreatingQuizServiceMock(),
            mlService: TemplateCreatingMLServiceMock()
        )

        await logic.handleQuizTypeInfoTap(.async)

        #expect(await presenter.quizTypeInfoRequests() == [.async])
    }
}

private actor TemplateCreatingPresenterSpy: TemplateCreatingPresenter {
    private var loadingStatesStorage: [Bool] = []
    private var createSuccessCalls = 0
    private var deleteSuccessCalls = 0
    private var serviceErrorsStorage: [QuizServiceError] = []
    private var quizTypeInfoRequestsStorage: [QuizType] = []

    func presentCreateTemplateLoading(_ isLoading: Bool) async {
        loadingStatesStorage.append(isLoading)
    }

    func presentCreateTemplateSuccess() async {
        createSuccessCalls += 1
    }

    func presentDeleteTemplateSuccess() async {
        deleteSuccessCalls += 1
    }

    func presentServiceError(_ error: QuizServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentQuizTypeInfo(_ quizType: QuizType) async {
        quizTypeInfoRequestsStorage.append(quizType)
    }

    func loadingStates() -> [Bool] {
        loadingStatesStorage
    }

    func createSuccessCallsCount() -> Int {
        createSuccessCalls
    }

    func deleteSuccessCallsCount() -> Int {
        deleteSuccessCalls
    }

    func serviceErrors() -> [QuizServiceError] {
        serviceErrorsStorage
    }

    func quizTypeInfoRequests() -> [QuizType] {
        quizTypeInfoRequestsStorage
    }
}

private actor TemplateCreatingQuizServiceMock: QuizService {
    private var createTemplateError: QuizServiceError?
    private var createTemplateRequestsStorage: [CreateTemplateRequest] = []
    private var updateTemplateRequestsStorage: [(id: String, request: CreateTemplateRequest)] = []
    private var deletedTemplateIDsStorage: [String] = []

    func setCreateTemplateError(_ error: QuizServiceError?) {
        createTemplateError = error
    }

    func lastCreateTemplateRequest() -> CreateTemplateRequest? {
        createTemplateRequestsStorage.last
    }

    func lastUpdatedTemplateID() -> String? {
        updateTemplateRequestsStorage.last?.id
    }

    func lastUpdateTemplateRequest() -> CreateTemplateRequest? {
        updateTemplateRequestsStorage.last?.request
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
        updateTemplateRequestsStorage.append((templateId, request))
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {
        createTemplateRequestsStorage.append(request)
        if let createTemplateError {
            throw createTemplateError
        }
    }

    func deleteTemplate(by templateId: String) async throws {
        deletedTemplateIDsStorage.append(templateId)
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

private actor TemplateCreatingMLServiceMock: MLService {
    private var paraphraseResult = ParaphrasedText(text: nil)
    private var paraphraseError: MLServiceError?
    private var paraphraseRequestsStorage: [ParaphraseMLRequest] = []
    private var generateQuestionsResult = GeneratedQuestions(questions: [])
    private var generateQuestionsError: MLServiceError?
    private var generateQuestionsRequestsStorage: [GenerateTemplateQuestionsMLRequest] = []

    func setParaphraseResult(_ result: ParaphrasedText) {
        paraphraseResult = result
    }

    func setParaphraseError(_ error: MLServiceError?) {
        paraphraseError = error
    }

    func setGenerateQuestionsResult(_ result: GeneratedQuestions) {
        generateQuestionsResult = result
    }

    func setGenerateQuestionsError(_ error: MLServiceError?) {
        generateQuestionsError = error
    }

    func paraphraseRequests() -> [ParaphraseMLRequest] {
        paraphraseRequestsStorage
    }

    func generateQuestionsRequests() -> [GenerateTemplateQuestionsMLRequest] {
        generateQuestionsRequestsStorage
    }

    func generateTemplate(_ request: GenerateTemplateMLRequest) async throws -> GeneratedTemplate {
        throw MLServiceError.unknown
    }

    func generateTemplateQuestions(_ request: GenerateTemplateQuestionsMLRequest) async throws -> GeneratedQuestions {
        generateQuestionsRequestsStorage.append(request)
        if let generateQuestionsError {
            throw generateQuestionsError
        }
        return generateQuestionsResult
    }

    func paraphrase(_ request: ParaphraseMLRequest) async throws -> ParaphrasedText {
        paraphraseRequestsStorage.append(request)
        if let paraphraseError {
            throw paraphraseError
        }
        return paraphraseResult
    }
}

private func makeQuestion(id: String, type: QuestionType) -> Question {
    Question(
        correctAnswer: nil,
        id: id,
        maxScore: 1,
        options: ["A", "B", "C"],
        text: "Question \(id)",
        timeLimitSec: nil,
        type: type
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
