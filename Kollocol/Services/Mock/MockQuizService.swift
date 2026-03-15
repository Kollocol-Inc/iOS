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
                        aiAnswer: "",
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        orderIndex: 0,
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    ),
                    Question(
                        aiAnswer: "",
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        orderIndex: 12,
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
                        aiAnswer: "",
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        orderIndex: 0,
                        text: "Question 1",
                        timeLimitSec: 30,
                        type: .openEnded
                    ),
                    Question(
                        aiAnswer: "",
                        correctAnswer: .openText("123"),
                        id: "123",
                        maxScore: 5,
                        options: [],
                        orderIndex: 12,
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

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        return [
            ParticipatingInstance(
                instance: QuizInstance(
                    accessCode: "127287",
                    createdAt: Date(),
                    deadline: "До 01.01.2026 12:00",
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
                    deadline: "До 01.01.2026 12:00",
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
        return [
            QuizInstance(
                accessCode: "127287",
                createdAt: Date(),
                deadline: "До 01.01.2026 12:00",
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
                deadline: "До 01.01.2026 12:00",
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
}
