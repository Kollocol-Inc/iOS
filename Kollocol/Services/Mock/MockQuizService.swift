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
                    status: .notStarted,
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
                    status: .notStarted,
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
                status: .notStarted,
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
                quizType: .async,
                settings: QuizSettings(
                    allowReview: true,
                    randomOrder: true,
                    showCorrectAnswer: true,
                    timeLimitTotal: true
                ),
                status: .notStarted,
                templateId: "123",
                title: "Коллоквиум iOS",
                totalQuestions: "10",
                totalTime: "1000"
            )
        ]
    }
}
