//
//  QuizParticipatingModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

enum QuizParticipatingModels {
    enum Phase {
        case participantAnswering
        case participantSubmittedWaitingOthers
        case participantWaitingForCreator
        case creatorWaitingParticipants
        case creatorReadyToContinue
        case quizFinished
    }

    struct ParticipantRowViewData {
        let participant: QuizParticipant
        let isDimmed: Bool
        let place: Int
        let score: Int
    }

    struct OptionViewData {
        let index: Int
        let text: String
        let kind: AnswerOptionMarkControl.Kind
        let isSelected: Bool
        let isEnabled: Bool
        let answersCount: Int
        let isAnswersCountVisible: Bool
    }

    struct QuestionInfoViewData {
        let questionNumber: Int
        let totalQuestions: Int
        let maxScore: Int
        let remainingSeconds: Int
        let isTimerVisible: Bool
    }

    struct FinalTopLeaderViewData {
        let participant: QuizParticipant
        let rank: Int
        let score: Int
    }

    struct PersonalResultViewData {
        let place: Int
        let score: Int
    }

    struct FinalParticipantRowViewData {
        let participant: QuizParticipant
        let rank: Int
        let score: Int
    }

    struct ViewState {
        let questionPayload: QuizQuestionPayload?
        let openAnswerText: String
        let selectedOptionIndexes: [Int]
        let phase: Phase
        let isCreator: Bool
        let participantRows: [ParticipantRowViewData]
        let optionAnswerCounts: [Int: Int]
        let waitingAnsweredCount: Int
        let waitingTotalParticipantsCount: Int
        let bottomButtonTitle: String
        let isBottomButtonEnabled: Bool
        let isTimerVisible: Bool
        let topLeaders: [FinalTopLeaderViewData]
        let personalResult: PersonalResultViewData?
        let finalParticipants: [FinalParticipantRowViewData]
    }

    enum Row {
        case header(title: String)
        case topLeaders([FinalTopLeaderViewData])
        case personalResult(PersonalResultViewData)
        case questionInfo(QuestionInfoViewData)
        case questionText(String)
        case openAnswerInput(text: String, isEditable: Bool)
        case answerOption(OptionViewData)
        case divider
        case participantsHeader(title: String, count: Int)
        case participant(ParticipantRowViewData)
        case finalParticipant(FinalParticipantRowViewData)
    }
}
