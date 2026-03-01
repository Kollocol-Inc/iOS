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

    // MARK: - Private Methods
    private func map(_ error: Error) -> QuizServiceError {
        if let e = error as? QuizServiceError { return e }

        guard let networkError = error as? NetworkError else {
            return .unknown
        }

        switch networkError {
        case .transport(let urlError):
            if urlError.code == .notConnectedToInternet { return .offline }
            return .unknown

        case .httpStatus(let code, _):
            if code == 400 { return .badRequest }
            if code == 401 { return .unauthorized }
            if (500...599).contains(code) { return .server }

            return .unknown

        default:
            return .unknown
        }
    }
}
