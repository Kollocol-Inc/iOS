//
//  QuizParticipantReviewProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

protocol QuizParticipantReviewInteractor: Actor {
    func handleViewDidLoad() async
    func handleQuestionTap(_ index: Int) async
    func handlePreviousQuestionTap() async
    func handleNextQuestionTap() async
    func handleScoreInputCommit(_ text: String?) async
    func handleDecreaseScoreTap() async
    func handleIncreaseScoreTap() async
    func handleAIReviewTap() async
    func handleGradeTap() async
    func handleCompletionTap() async
}

protocol QuizParticipantReviewPresenter {
    func presentViewData(_ viewData: QuizParticipantReviewModels.ViewData) async
    func presentCompletionInfo(pendingOpenQuestionsCount: Int) async
    func presentServiceError(_ error: QuizServiceError) async
}
