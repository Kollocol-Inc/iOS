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
    func routeToProfileScreen() async
    func joinQuiz(code: String) async
}

protocol MainPresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentQuizzes(participating: [QuizInstance], hosting: [QuizInstance]) async
    func presentUserServiceError(_ error: UserServiceError) async
    func presentQuizServiceError(_ error: QuizServiceError) async
    func presentProfileScreen() async
    func presentJoinQuizSuccess() async
    func presentJoinQuizError() async
}
