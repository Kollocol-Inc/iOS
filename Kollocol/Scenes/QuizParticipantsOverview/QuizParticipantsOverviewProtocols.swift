//
//  QuizParticipantsOverviewProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

protocol QuizParticipantsOverviewInteractor: Actor {
    func fetchParticipants() async
    func publishQuizResults() async
    func handleParticipantTap(
        participantId: String?,
        fullName: String,
        email: String?
    ) async
}

protocol QuizParticipantsOverviewPresenter {
    func presentParticipants(_ participants: [QuizInstanceParticipant]) async
    func presentPublishQuizResultsSuccess() async
    func presentParticipantReview(_ initialData: QuizParticipantReviewModels.InitialData) async
    func presentServiceError(_ error: QuizServiceError) async
}
