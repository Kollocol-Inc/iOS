//
//  MockQuizService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

// MARK: - MockQuizServiceImpl
actor MockQuizServiceImpl: QuizService {
    // MARK: - Lifecycle

    init() {
    }

    // MARK: - Methods

    func getTemplates() async throws -> [QuizTemplate] {
        return [
            QuizTemplate(
                createdAt: Date(),
                description: "описание",
                id: "123",
                questions: [
                    Question(
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    ),
                    Question(
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    )
                ],
                quizType: .async,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: true,
                    showCorrectAnswer: true,
                    timeLimitTotal: true
                ),
                title: "Testik",
                updatedAt: Date(),
                userId: "123"
            ),
            QuizTemplate(
                createdAt: Date(),
                description: "описание",
                id: "123",
                questions: [
                    Question(
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    ),
                    Question(
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    )
                ],
                quizType: .async,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: true,
                    showCorrectAnswer: true,
                    timeLimitTotal: true
                ),
                title: "Hello",
                updatedAt: Date(),
                userId: "123"
            )
        ]
    }

    func getTemplate(by templateId: String) async throws -> QuizTemplate {
        return QuizTemplate(
            createdAt: Date(),
            description: "описание",
            id: "123",
            questions: [
                Question(
                    correctAnswer: .openText("123"),
                    id: "123",
                    maxScore: 5,
                    options: [],
                    text: "Question 1",
                    timeLimitSec: 30,
                    type: .openEnded
                ),
                Question(
                    correctAnswer: .openText("123"),
                    id: "123",
                    maxScore: 5,
                    options: [],
                    text: "Question 1",
                    timeLimitSec: 30,
                    type: .openEnded
                )
            ],
            quizType: .async,
            settings: QuizSettings(
                allowReview: true,
                randomOrder: true,
                showCorrectAnswer: true,
                timeLimitTotal: true
            ),
            title: "Testik",
            updatedAt: Date(),
            userId: "123"
        )
    }

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        return try await getParticipatingQuizzes(sessionStatus: nil)
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        return [
            ParticipatingInstance(
                instance: QuizInstance(
                    accessCode: "127287",
                    createdAt: Date(),
                    deadline: Date(),
                    groupId: "123",
                    hostUserId: "123",
                    id: "123",
                    quizType: .async,
                    settings: QuizSettings(
                        allowReview: true,
                        randomOrder: true,
                        showCorrectAnswer: true,
                        timeLimitTotal: true
                    ),
                    status: .active,
                    templateId: "123",
                    title: "Коллоквиум iOS",
                    totalQuestions: "10",
                    totalTime: "1000"
                ),
                sessionStatus: .notStarted
            ),
            ParticipatingInstance(
                instance: QuizInstance(
                    accessCode: "127287",
                    createdAt: Date(),
                    deadline: Date(),
                    groupId: "123",
                    hostUserId: "123",
                    id: "123",
                    quizType: .sync,
                    settings: QuizSettings(
                        allowReview: true,
                        randomOrder: true,
                        showCorrectAnswer: true,
                        timeLimitTotal: true
                    ),
                    status: .active,
                    templateId: "123",
                    title: "Коллоквиум Android",
                    totalQuestions: "10",
                    totalTime: "1000"
                ),
                sessionStatus: .notStarted
            )
        ]
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        return try await getHostingQuizzes(status: nil)
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        return [
            QuizInstance(
                accessCode: "127287",
                createdAt: Date(),
                deadline: Date(),
                groupId: "123",
                hostUserId: "123",
                id: "123",
                quizType: .async,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: true,
                    showCorrectAnswer: true,
                    timeLimitTotal: true
                ),
                status: .active,
                templateId: "123",
                title: "Коллоквиум iOS",
                totalQuestions: "10",
                totalTime: "1000"
            ),
            QuizInstance(
                accessCode: "127287",
                createdAt: Date(),
                deadline: Date(),
                groupId: "123",
                hostUserId: "123",
                id: "123",
                quizType: .sync,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: true,
                    showCorrectAnswer: true,
                    timeLimitTotal: true
                ),
                status: .active,
                templateId: "123",
                title: "Коллоквиум iOS",
                totalQuestions: "10",
                totalTime: "1000"
            )
        ]
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {

    }

    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws {

    }

    func deleteTemplate(by templateId: String) async throws {

    }

    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String? {
        return "127287"
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        return QuizInstanceDetails(
            instance: QuizInstance(
                accessCode: "127287",
                createdAt: Date(),
                deadline: Date(),
                groupId: "123",
                hostUserId: "123",
                id: instanceId,
                quizType: .sync,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: false,
                    showCorrectAnswer: true,
                    timeLimitTotal: false
                ),
                status: .pendingReview,
                templateId: "123",
                title: "Пробный квиз",
                totalQuestions: "2",
                totalTime: "120"
            ),
            questions: [
                Question(
                    correctAnswer: .singleChoice(0),
                    id: "q1",
                    maxScore: 1,
                    options: ["4", "5", "6"],
                    text: "Сколько будет 2 + 2?",
                    timeLimitSec: 30,
                    type: .singleChoice
                ),
                Question(
                    correctAnswer: .openText("MVC"),
                    id: "q2",
                    maxScore: 2,
                    options: nil,
                    text: "Назовите архитектуру iOS, которую знаете",
                    timeLimitSec: 60,
                    type: .openEnded
                )
            ]
        )
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        return [
            QuizInstanceParticipant(
                maxPossibleScore: 3,
                reviewStatus: .pendingReview,
                sessionStatus: .finished,
                totalScore: 1,
                userId: "user-1"
            ),
            QuizInstanceParticipant(
                maxPossibleScore: 3,
                reviewStatus: .reviewed,
                sessionStatus: .finished,
                totalScore: 3,
                userId: "user-2"
            )
        ]
    }

    func getParticipantAnswers(
        instanceId: String,
        participantId: String
    ) async throws -> QuizParticipantAnswersDetails {
        let instance = try await getQuizInstance(by: instanceId)
        return QuizParticipantAnswersDetails(
            answers: [
                QuizParticipantAnswer(
                    answer: "0",
                    isCorrect: true,
                    questionId: "q1",
                    score: 1,
                    timeSpentMs: 5400
                ),
                QuizParticipantAnswer(
                    answer: "Model View Controller",
                    isCorrect: nil,
                    questionId: "q2",
                    score: nil,
                    timeSpentMs: 17000
                )
            ],
            instance: instance.instance,
            questions: instance.questions
        )
    }

    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws {

    }

    func reviewParticipantAnswer(
        instanceId: String,
        request: ReviewAnswerRequest
    ) async throws -> QuizAnswerReviewSuggestion {
        return QuizAnswerReviewSuggestion(
            feedback: "Ответ частично корректен. Стоит конкретизировать формулировку.",
            suggestedScore: 1
        )
    }

    func publishQuizResults(instanceId: String) async throws {

    }
}
