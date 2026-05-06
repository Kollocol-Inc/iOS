//
//  StartQuizProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

protocol StartQuizInteractor: Actor {
    func fetchOwnedGroups() async
    func handleBackTap() async
    func startQuiz(formData: StartQuizModels.FormData) async
}

protocol StartQuizPresenter {
    func presentOwnedGroups(_ groups: [Group]) async
    func presentStartQuizLoading(_ isLoading: Bool) async
    func presentStartQuizSuccess() async
    func presentStartSyncQuizSuccess(accessCode: String) async
    func presentServiceError(_ error: QuizServiceError) async
    func presentJoinQuizError(_ error: QuizParticipationServiceError) async
    func presentCloseScreen() async
}
