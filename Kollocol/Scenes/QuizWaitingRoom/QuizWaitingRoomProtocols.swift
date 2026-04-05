//
//  QuizWaitingRoomProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

protocol QuizWaitingRoomInteractor: Actor {
    func handleViewDidLoad() async
    func handleLeaveAttempt() async
    func handleLeaveTap() async
    func handleStartQuizTap() async
    func handleKickParticipantTap(_ participant: QuizParticipant) async
    func handleKickParticipantConfirmed(email: String) async
}

protocol QuizWaitingRoomPresenter {
    func presentIsCreator(_ isCreator: Bool) async
    func presentCurrentUserID(_ userID: String?) async
    func presentQuizTitle(_ quizTitle: String) async
    func presentParticipantsCount(_ count: Int) async
    func presentParticipants(_ participants: [QuizParticipant]) async
    func presentRouteToQuizParticipating() async
    func presentServiceError(_ error: QuizParticipationServiceError) async
    func presentServerError(message: String) async
    func presentKickParticipantConfirmation(participantName: String, participantEmail: String) async
    func presentKickedFromQuiz(quizTitle: String?) async
    func presentSessionReplaced() async
    func presentLeaveConfirmation() async
    func presentCloseFlow() async
}
