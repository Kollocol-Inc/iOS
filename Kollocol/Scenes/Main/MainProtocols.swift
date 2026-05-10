//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol MainInteractor {
    func fetchUserProfile() async
    func fetchQuizzes() async
    func fetchNotificationsBadge() async
    func routeToProfileScreen() async
    func routeToNotificationsScreen() async
    func joinQuiz(code: String, skipAsyncConfirmation: Bool) async
    func handleQuizCardTap(_ quiz: QuizInstanceViewData) async
    func handleQuizTypeTap(_ quizType: QuizType) async
}

protocol MainPresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentQuizzes(participating: [QuizInstance], hosting: [QuizInstance]) async
    func presentNotificationsBadge(unreadCount: Int) async
    func presentServiceError(_ error: any UserFacingError) async
    func presentProfileScreen() async
    func presentNotificationsScreen() async
    func presentQuizParticipantsOverview(_ initialData: QuizParticipantsOverviewModels.InitialData) async
    func presentJoinQuizSuccess(accessCode: String) async
    func presentJoinQuizError(_ error: QuizParticipationServiceError) async
    func presentJoinQuizConfirmation(accessCode: String, quizTitle: String) async
    func presentAsyncQuizStartConfirmation(accessCode: String, quizTitle: String?) async
    func presentQuizTypeInfo(_ quizType: QuizType) async
}
