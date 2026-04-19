//
//  QuizParticipantReviewModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

enum QuizParticipantReviewModels {
    enum AnswerInfoBadge {
        case correctAnswer
        case ai
        case aiLoading
    }

    struct InitialData {
        let instanceId: String
        let participantId: String
        let participantFullName: String
        let participantEmail: String?
        let quizTitle: String
    }

    enum CheckmarkState {
        case pending(pendingOpenQuestionsCount: Int)
        case complete
    }

    enum QuestionSwitcherBorderStyle {
        case neutral
        case correct
        case incorrect
        case none
        case selected
    }

    struct QuestionSwitcherItemViewData {
        let questionNumber: Int
        let maxScore: Int
        let borderStyle: QuestionSwitcherBorderStyle
        let hasFilledBackground: Bool
    }

    enum OptionTextStyle {
        case neutral
        case correct
        case incorrect
    }

    struct OptionRowViewData {
        let text: String
        let kind: AnswerOptionMarkControl.Kind
        let isSelected: Bool
        let visualState: AnswerOptionMarkControl.VisualState
        let textStyle: OptionTextStyle
    }

    struct ScoreControlViewData {
        let score: Int
        let maxScore: Int
        let isMinusEnabled: Bool
        let isPlusEnabled: Bool
        let isVisible: Bool
    }

    struct BottomControlsViewData {
        let isVisible: Bool
        let showsGradeButton: Bool
        let showsAIReviewButton: Bool
        let canGoPrevious: Bool
        let canGoNext: Bool
    }

    struct AnswerInfoViewData {
        let badge: AnswerInfoBadge
        let text: String
    }

    struct ViewData {
        let rows: [Row]
        let selectedQuestionIndex: Int
        let checkmarkState: CheckmarkState
        let scoreControl: ScoreControlViewData
        let bottomControls: BottomControlsViewData
    }

    enum Row {
        case header(title: String)
        case questionSwitcher(items: [QuestionSwitcherItemViewData])
        case questionText(text: String)
        case openAnswer(text: String)
        case answerInfo(AnswerInfoViewData)
        case option(OptionRowViewData)
        case empty(text: String)
    }
}
