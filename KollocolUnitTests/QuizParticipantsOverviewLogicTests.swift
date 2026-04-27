//
//  QuizParticipantsOverviewLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizParticipantsOverviewLogicTests {
    @Test
    func fetchParticipantsSuccessPresentsParticipants() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let quizService = QuizParticipantsOverviewQuizServiceMock()
        let participants = [makeParticipant(userId: "u1")]
        await quizService.setParticipantsResult(participants)
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: quizService,
            instanceId: "instance-1",
            quizTitle: "Quiz"
        )

        await logic.fetchParticipants()

        #expect(await quizService.requestedParticipantsInstanceIDs() == ["instance-1"])
        #expect(await presenter.participantsPayloadsCount() == 1)
        #expect(await presenter.lastParticipants().count == 1)
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func publishQuizResultsSuccessPresentsSuccess() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let quizService = QuizParticipantsOverviewQuizServiceMock()
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: quizService,
            instanceId: "instance-2",
            quizTitle: "Quiz"
        )

        await logic.publishQuizResults()

        #expect(await quizService.publishedInstanceIDs() == ["instance-2"])
        #expect(await presenter.publishSuccessCallsCount() == 1)
    }

    @Test
    func cancelQuizSuccessPresentsCanceledQuizTitle() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let quizService = QuizParticipantsOverviewQuizServiceMock()
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: quizService,
            instanceId: "instance-3",
            quizTitle: "Async physics"
        )

        await logic.cancelQuiz()

        #expect(await quizService.deletedInstanceIDs() == ["instance-3"])
        #expect(await presenter.canceledTitles() == ["Async physics"])
    }

    @Test
    func serviceErrorIsPresented() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let quizService = QuizParticipantsOverviewQuizServiceMock()
        await quizService.setParticipantsError(.offline)
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: quizService,
            instanceId: "instance-4",
            quizTitle: "Quiz"
        )

        await logic.fetchParticipants()

        let errors = await presenter.serviceErrors()
        #expect(errors.count == 1)
        #expect(isQuizServiceError(errors.first, .offline))
    }

    @Test
    func handleParticipantTapIgnoresEmptyParticipantId() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: QuizParticipantsOverviewQuizServiceMock(),
            instanceId: "instance-5",
            quizTitle: "Quiz"
        )

        await logic.handleParticipantTap(participantId: "   ", fullName: "Name", email: "a@b.c")

        #expect(await presenter.participantReviewPayloads().isEmpty)
    }

    @Test
    func handleParticipantTapRoutesWithTrimmedId() async {
        let presenter = QuizParticipantsOverviewPresenterSpy()
        let logic = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: QuizParticipantsOverviewQuizServiceMock(),
            instanceId: "instance-6",
            quizTitle: "Final quiz"
        )

        await logic.handleParticipantTap(
            participantId: "  participant-1  ",
            fullName: "Alex Stone",
            email: "alex@example.com"
        )

        let payloads = await presenter.participantReviewPayloads()
        #expect(payloads.count == 1)
        #expect(payloads.first?.instanceId == "instance-6")
        #expect(payloads.first?.participantId == "participant-1")
        #expect(payloads.first?.participantFullName == "Alex Stone")
        #expect(payloads.first?.quizTitle == "Final quiz")
    }
}

private actor QuizParticipantsOverviewPresenterSpy: QuizParticipantsOverviewPresenter {
    private var participantsPayloadsStorage: [[QuizInstanceParticipant]] = []
    private var publishSuccessCalls = 0
    private var canceledTitlesStorage: [String] = []
    private var participantReviewPayloadsStorage: [QuizParticipantReviewModels.InitialData] = []
    private var serviceErrorsStorage: [QuizServiceError] = []

    func presentParticipants(_ participants: [QuizInstanceParticipant]) async {
        participantsPayloadsStorage.append(participants)
    }

    func presentPublishQuizResultsSuccess() async {
        publishSuccessCalls += 1
    }

    func presentQuizCanceled(quizTitle: String) async {
        canceledTitlesStorage.append(quizTitle)
    }

    func presentParticipantReview(_ initialData: QuizParticipantReviewModels.InitialData) async {
        participantReviewPayloadsStorage.append(initialData)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func participantsPayloadsCount() -> Int {
        participantsPayloadsStorage.count
    }

    func lastParticipants() -> [QuizInstanceParticipant] {
        participantsPayloadsStorage.last ?? []
    }

    func publishSuccessCallsCount() -> Int {
        publishSuccessCalls
    }

    func canceledTitles() -> [String] {
        canceledTitlesStorage
    }

    func participantReviewPayloads() -> [QuizParticipantReviewModels.InitialData] {
        participantReviewPayloadsStorage
    }

    func serviceErrors() -> [QuizServiceError] {
        serviceErrorsStorage
    }
}

private actor QuizParticipantsOverviewQuizServiceMock: QuizService {
    private var participantsResult: [QuizInstanceParticipant] = []
    private var participantsError: QuizServiceError?
    private var requestedParticipantsInstanceIDsStorage: [String] = []
    private var publishedInstanceIDsStorage: [String] = []
    private var deletedInstanceIDsStorage: [String] = []

    func setParticipantsResult(_ participants: [QuizInstanceParticipant]) {
        participantsResult = participants
    }

    func setParticipantsError(_ error: QuizServiceError?) {
        participantsError = error
    }

    func requestedParticipantsInstanceIDs() -> [String] {
        requestedParticipantsInstanceIDsStorage
    }

    func publishedInstanceIDs() -> [String] {
        publishedInstanceIDsStorage
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
        nil
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        throw QuizServiceError.unknown
    }

    func deleteQuizInstance(by instanceId: String) async throws {
        deletedInstanceIDsStorage.append(instanceId)
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        requestedParticipantsInstanceIDsStorage.append(instanceId)
        if let participantsError {
            throw participantsError
        }
        return participantsResult
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
        publishedInstanceIDsStorage.append(instanceId)
    }
}

private func makeParticipant(userId: String) -> QuizInstanceParticipant {
    QuizInstanceParticipant(
        avatarURL: nil,
        email: "participant@example.com",
        firstName: "First",
        lastName: "Last",
        maxPossibleScore: 10,
        reviewStatus: .pendingReview,
        sessionStatus: .inProgress,
        totalScore: 5,
        userId: userId
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
