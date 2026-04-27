//
//  QuizParticipantReviewLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizParticipantReviewLogicTests {
    @Test
    func viewDidLoadSuccessPresentsOpenQuestionState() async {
        let presenter = QuizParticipantReviewPresenterSpy()
        let quizService = QuizParticipantReviewQuizServiceMock()
        await quizService.setDetailsResult(
            makeDetails(
                quizTitle: "  Service title  ",
                answers: [
                    .init(
                        answer: "Participant open answer",
                        isCorrect: nil,
                        isReviewed: false,
                        questionId: "q-open",
                        score: 1,
                        timeSpentMs: nil
                    )
                ],
                questions: [makeOpenQuestion(id: "q-open", maxScore: 5)]
            )
        )

        let logic = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: .init(
                instanceId: "instance-1",
                participantId: "participant-1",
                participantFullName: "Student",
                participantEmail: "student@example.com",
                quizTitle: "Fallback"
            )
        )

        await logic.handleViewDidLoad()

        #expect(await presenter.viewDataCount() == 1)
        let viewData = await presenter.lastViewData()
        #expect(viewData?.selectedQuestionIndex == 0)
        #expect(viewData?.scoreControl.isVisible == true)
        #expect(viewData?.scoreControl.score == 1)
        #expect(viewData?.bottomControls.showsGradeButton == true)
        #expect(viewData?.bottomControls.showsAIReviewButton == true)
        #expect(await presenter.serviceErrors().isEmpty)

        let pending = await presenter.pendingOpenCount(from: viewData)
        #expect(pending == 1)
        #expect(await presenter.headerTitle(from: viewData) == "Service title")
    }

    @Test
    func scoreCommitAndGradeTapClampScoreAndSendGradeRequest() async {
        let presenter = QuizParticipantReviewPresenterSpy()
        let quizService = QuizParticipantReviewQuizServiceMock()
        await quizService.setDetailsResult(
            makeDetails(
                quizTitle: "Quiz",
                answers: [
                    .init(
                        answer: "Answer",
                        isCorrect: nil,
                        isReviewed: false,
                        questionId: "q-open",
                        score: 1,
                        timeSpentMs: nil
                    )
                ],
                questions: [makeOpenQuestion(id: "q-open", maxScore: 5)]
            )
        )

        let logic = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: .init(
                instanceId: "instance-2",
                participantId: "  participant-2  ",
                participantFullName: "Student",
                participantEmail: nil,
                quizTitle: "Quiz"
            )
        )

        await logic.handleViewDidLoad()
        await logic.handleScoreInputCommit("999")
        await logic.handleGradeTap()

        let gradeRequests = await quizService.gradeRequests()
        #expect(gradeRequests.count == 1)
        #expect(gradeRequests.first?.instanceId == "instance-2")
        #expect(gradeRequests.first?.participantId == "participant-2")
        #expect(gradeRequests.first?.questionId == "q-open")
        #expect(gradeRequests.first?.score == 5)

        let viewData = await presenter.lastViewData()
        #expect(viewData?.scoreControl.score == 5)
        #expect(viewData?.bottomControls.showsGradeButton == false)

        let pending = await presenter.pendingOpenCount(from: viewData)
        #expect(pending == 0)
    }

    @Test
    func aiReviewSuccessAppliesSuggestedScoreAndShowsAIInfo() async {
        let presenter = QuizParticipantReviewPresenterSpy()
        let quizService = QuizParticipantReviewQuizServiceMock()
        await quizService.setDetailsResult(
            makeDetails(
                quizTitle: "Quiz",
                answers: [
                    .init(
                        answer: "Open answer",
                        isCorrect: nil,
                        isReviewed: false,
                        questionId: "q-open",
                        score: 0,
                        timeSpentMs: nil
                    )
                ],
                questions: [makeOpenQuestion(id: "q-open", maxScore: 5)]
            )
        )
        await quizService.setReviewResult(
            .init(
                feedback: "Great structure",
                suggestedScore: 4
            )
        )

        let logic = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: .init(
                instanceId: "instance-3",
                participantId: " participant-3 ",
                participantFullName: "Student",
                participantEmail: nil,
                quizTitle: "Quiz"
            )
        )

        await logic.handleViewDidLoad()
        await logic.handleAIReviewTap()

        let reviewRequests = await quizService.reviewRequests()
        #expect(reviewRequests.count == 1)
        #expect(reviewRequests.first?.instanceId == "instance-3")
        #expect(reviewRequests.first?.participantId == "participant-3")
        #expect(reviewRequests.first?.questionId == "q-open")

        #expect(await presenter.viewDataCount() >= 3)
        let viewData = await presenter.lastViewData()
        #expect(viewData?.scoreControl.score == 4)
        #expect(viewData?.bottomControls.showsAIReviewButton == false)
        #expect(await presenter.hasAIBadge(in: viewData) == true)
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func aiReviewFailurePresentsErrorAndRestoresAIButton() async {
        let presenter = QuizParticipantReviewPresenterSpy()
        let quizService = QuizParticipantReviewQuizServiceMock()
        await quizService.setDetailsResult(
            makeDetails(
                quizTitle: "Quiz",
                answers: [
                    .init(
                        answer: "Open answer",
                        isCorrect: nil,
                        isReviewed: false,
                        questionId: "q-open",
                        score: 0,
                        timeSpentMs: nil
                    )
                ],
                questions: [makeOpenQuestion(id: "q-open", maxScore: 5)]
            )
        )
        await quizService.setReviewError(.offline)

        let logic = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: .init(
                instanceId: "instance-4",
                participantId: "participant-4",
                participantFullName: "Student",
                participantEmail: nil,
                quizTitle: "Quiz"
            )
        )

        await logic.handleViewDidLoad()
        await logic.handleAIReviewTap()

        let errors = await presenter.serviceErrors()
        #expect(errors.count == 1)
        #expect(isQuizServiceError(errors.first, .offline))

        let viewData = await presenter.lastViewData()
        #expect(viewData?.bottomControls.showsAIReviewButton == true)
        #expect(await presenter.hasAILoadingBadge(in: viewData) == false)
    }

    @Test
    func completionTapPresentsPendingOpenQuestionsCount() async {
        let presenter = QuizParticipantReviewPresenterSpy()
        let quizService = QuizParticipantReviewQuizServiceMock()
        await quizService.setDetailsResult(
            makeDetails(
                quizTitle: "Quiz",
                answers: [
                    .init(
                        answer: "Reviewed",
                        isCorrect: nil,
                        isReviewed: true,
                        questionId: "q-1",
                        score: 3,
                        timeSpentMs: nil
                    ),
                    .init(
                        answer: "Pending",
                        isCorrect: nil,
                        isReviewed: false,
                        questionId: "q-2",
                        score: 0,
                        timeSpentMs: nil
                    )
                ],
                questions: [
                    makeOpenQuestion(id: "q-1", maxScore: 5),
                    makeOpenQuestion(id: "q-2", maxScore: 5)
                ]
            )
        )

        let logic = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: .init(
                instanceId: "instance-5",
                participantId: "participant-5",
                participantFullName: "Student",
                participantEmail: nil,
                quizTitle: "Quiz"
            )
        )

        await logic.handleViewDidLoad()
        await logic.handleCompletionTap()

        #expect(await presenter.completionPendingCounts() == [1])
    }
}

private actor QuizParticipantReviewPresenterSpy: QuizParticipantReviewPresenter {
    private var viewDataStorage: [QuizParticipantReviewModels.ViewData] = []
    private var completionPendingCountsStorage: [Int] = []
    private var serviceErrorsStorage: [QuizServiceError] = []

    func presentViewData(_ viewData: QuizParticipantReviewModels.ViewData) async {
        viewDataStorage.append(viewData)
    }

    func presentCompletionInfo(pendingOpenQuestionsCount: Int) async {
        completionPendingCountsStorage.append(pendingOpenQuestionsCount)
    }

    func presentServiceError(_ error: QuizServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func viewDataCount() -> Int {
        viewDataStorage.count
    }

    func lastViewData() -> QuizParticipantReviewModels.ViewData? {
        viewDataStorage.last
    }

    func completionPendingCounts() -> [Int] {
        completionPendingCountsStorage
    }

    func serviceErrors() -> [QuizServiceError] {
        serviceErrorsStorage
    }

    func headerTitle(from viewData: QuizParticipantReviewModels.ViewData?) -> String? {
        guard let viewData else { return nil }
        for row in viewData.rows {
            if case let .header(title) = row {
                return title
            }
        }
        return nil
    }

    func pendingOpenCount(from viewData: QuizParticipantReviewModels.ViewData?) -> Int? {
        guard let viewData else { return nil }
        switch viewData.checkmarkState {
        case .pending(let pendingOpenQuestionsCount):
            return pendingOpenQuestionsCount
        case .complete:
            return 0
        }
    }

    func hasAIBadge(in viewData: QuizParticipantReviewModels.ViewData?) -> Bool {
        guard let viewData else { return false }

        for row in viewData.rows {
            if case let .answerInfo(info) = row,
               info.badge == .ai {
                return true
            }
        }

        return false
    }

    func hasAILoadingBadge(in viewData: QuizParticipantReviewModels.ViewData?) -> Bool {
        guard let viewData else { return false }

        for row in viewData.rows {
            if case let .answerInfo(info) = row,
               info.badge == .aiLoading {
                return true
            }
        }

        return false
    }
}

private actor QuizParticipantReviewQuizServiceMock: QuizService {
    private var detailsResult: QuizParticipantAnswersDetails?
    private var detailsError: QuizServiceError?
    private var reviewResult: QuizAnswerReviewSuggestion?
    private var reviewError: QuizServiceError?
    private var reviewRequestsStorage: [(instanceId: String, participantId: String, questionId: String)] = []
    private var gradeError: QuizServiceError?
    private var gradeRequestsStorage: [(instanceId: String, participantId: String, questionId: String, score: Int?)] = []

    func setDetailsResult(_ details: QuizParticipantAnswersDetails) {
        detailsResult = details
    }

    func setDetailsError(_ error: QuizServiceError?) {
        detailsError = error
    }

    func setReviewResult(_ suggestion: QuizAnswerReviewSuggestion?) {
        reviewResult = suggestion
    }

    func setReviewError(_ error: QuizServiceError?) {
        reviewError = error
    }

    func setGradeError(_ error: QuizServiceError?) {
        gradeError = error
    }

    func reviewRequests() -> [(instanceId: String, participantId: String, questionId: String)] {
        reviewRequestsStorage
    }

    func gradeRequests() -> [(instanceId: String, participantId: String, questionId: String, score: Int?)] {
        gradeRequestsStorage
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
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        []
    }

    func getParticipantAnswers(instanceId: String, participantId: String) async throws -> QuizParticipantAnswersDetails {
        if let detailsError {
            throw detailsError
        }

        guard let detailsResult else {
            throw QuizServiceError.unknown
        }

        return detailsResult
    }

    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws {
        gradeRequestsStorage.append((instanceId, request.participantId, request.questionId, request.score))
        if let gradeError {
            throw gradeError
        }
    }

    func reviewParticipantAnswer(
        instanceId: String,
        request: ReviewAnswerRequest
    ) async throws -> QuizAnswerReviewSuggestion {
        reviewRequestsStorage.append((instanceId, request.participantId, request.questionId))

        if let reviewError {
            throw reviewError
        }

        guard let reviewResult else {
            throw QuizServiceError.unknown
        }

        return reviewResult
    }

    func publishQuizResults(instanceId: String) async throws {
    }
}

private func makeDetails(
    quizTitle: String,
    answers: [QuizParticipantAnswer],
    questions: [Question]
) -> QuizParticipantAnswersDetails {
    QuizParticipantAnswersDetails(
        answers: answers,
        instance: QuizInstance(
            accessCode: nil,
            createdAt: nil,
            deadline: nil,
            groupId: nil,
            hostUserId: nil,
            id: "instance",
            quizType: .sync,
            settings: nil,
            status: .pendingReview,
            templateId: nil,
            title: quizTitle,
            totalQuestions: nil,
            totalTime: nil
        ),
        questions: questions
    )
}

private func makeOpenQuestion(id: String, maxScore: Int) -> Question {
    Question(
        correctAnswer: .openText("Expected answer"),
        id: id,
        maxScore: maxScore,
        options: nil,
        text: "Open question",
        timeLimitSec: 30,
        type: .openEnded
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
