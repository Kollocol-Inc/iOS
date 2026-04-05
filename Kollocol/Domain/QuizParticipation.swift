//
//  QuizParticipation.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

enum QuizParticipationConnectionState: Sendable, Equatable {
    case disconnected
    case connecting(accessCode: String)
    case connected(accessCode: String)
}

enum QuizParticipationStreamFailure: Sendable, Equatable {
    case offline
    case unauthorized
    case connectionClosed
    case connectionTimeout
    case unknown
}

struct QuizConnectedPayload: Sendable, Equatable {
    let sessionId: String?
    let quizType: QuizType?
    let quizStatus: QuizStatus?
    let isCreator: Bool
}

struct QuizParticipant: Sendable, Equatable {
    let userId: String?
    let firstName: String?
    let lastName: String?
    let email: String?
    let avatarURL: String?
    let isCreator: Bool
    let isOnline: Bool?
}

enum QuizParticipantsUpdateAction: String, Sendable {
    case joined = "joined"
    case left = "left"
    case answered = "answered"
}

struct QuizParticipantsUpdatePayload: Sendable, Equatable {
    let action: QuizParticipantsUpdateAction?
    let userId: String?
    let user: QuizParticipant?
    let count: Int
    let participants: [QuizParticipant]?
}

struct QuizParticipantsListPayload: Sendable, Equatable {
    let participants: [QuizParticipant]
    let quizTitle: String?
}

struct QuizQuestionData: Sendable, Equatable {
    let id: String?
    let text: String?
    let type: QuestionType?
    let options: [String]
    let orderIndex: Int?
    let maxScore: Int?
    let timeLimitSec: Int?
}

struct QuizQuestionPayload: Sendable, Equatable {
    let question: QuizQuestionData
    let questionIndex: Int
    let totalQuestions: Int
    let timeLimitMs: Int64?
    let serverTime: Int64?
}

struct QuizAnswerResultPayload: Sendable, Equatable {
    let userId: String?
    let isCorrect: Bool
    let score: Int
    let timeSpentMs: Int64
    let totalScore: Int
}

struct QuizLeaderboardEntryPayload: Sendable, Equatable {
    let user: QuizParticipant
    let rank: Int
    let score: Int
    let isAnswered: Bool
}

struct QuizAnswerOptionStatsPayload: Sendable, Equatable {
    let option: String
    let count: Int
}

struct QuizLeaderboardPayload: Sendable, Equatable {
    let leaderboard: [QuizLeaderboardEntryPayload]
    let questionStats: QuizQuestionStatsPayload?
    let answerOptionStats: [QuizAnswerOptionStatsPayload]
    let canContinue: Bool
    let question: QuizQuestionPayload?
}

struct QuizAnswerProgressPayload: Sendable, Equatable {
    let participantsAnswered: Int
    let totalParticipants: Int
}

struct QuizQuestionStatsPayload: Sendable, Equatable {
    let text: String?
    let type: QuestionType?
    let options: [String]
    let orderIndex: Int?
    let maxScore: Int?
    let timeLimitSec: Int?
}

struct QuizWaitingForCreatorPayload: Sendable, Equatable {
    let questionIndex: Int
    let reason: String?
}

struct QuizFinishedPayload: Sendable, Equatable {
    let finalScore: Int?
    let rank: Int?
}

struct QuizTimeExpiredPayload: Sendable, Equatable {
    let questionIndex: Int
}

enum QuizParticipationMessage: Sendable, Equatable {
    case connected(QuizConnectedPayload)
    case participantsUpdate(QuizParticipantsUpdatePayload)
    case participantsList(QuizParticipantsListPayload)
    case quizStarted(quizType: QuizType?)
    case question(QuizQuestionPayload)
    case answerProgress(QuizAnswerProgressPayload)
    case answerResult(QuizAnswerResultPayload)
    case leaderboard(QuizLeaderboardPayload)
    case timeExpired(QuizTimeExpiredPayload)
    case waitingForCreator(QuizWaitingForCreatorPayload)
    case quizFinished(QuizFinishedPayload)
    case error(message: String)
    case unknown(type: String, payloadSummary: String?, rawText: String)
}

enum QuizParticipationEvent: Sendable, Equatable {
    case connectionChanged(QuizParticipationConnectionState)
    case message(QuizParticipationMessage)
    case failure(QuizParticipationStreamFailure)
}
