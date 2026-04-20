//
//  QuizParticipatingProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

protocol QuizParticipatingInteractor: Actor {
    func handleViewDidLoad() async
    func handleLeaveAttempt() async
    func handleLeaveTap() async
    func handleCancelQuizTap() async
    func handleSubmitTap() async
    func handleOptionTap(_ index: Int) async
    func handleOpenAnswerTextChanged(_ text: String) async
}

protocol QuizParticipatingPresenter {
    func presentQuizTitle(_ quizTitle: String) async
    func presentState(_ state: QuizParticipatingModels.ViewState) async
    func presentServiceError(_ error: QuizParticipationServiceError) async
    func presentServerError(message: String) async
    func presentKickedFromQuiz(quizTitle: String?) async
    func presentSessionReplaced() async
    func presentQuizDeletedByCreator() async
    func presentQuizCanceled(quizTitle: String) async
    func presentLeaveConfirmation() async
    func presentCloseFlow() async
}
