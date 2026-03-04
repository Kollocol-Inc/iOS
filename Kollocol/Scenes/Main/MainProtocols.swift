//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol MainInteractor {
    func fetchUserProfile() async
    func fetchParticipatingQuizzes() async
    func fetchHostingQuizzes() async
    func routeToProfileScreen() async
    func joinQuiz(code: String) async
}

protocol MainPresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentParticipatingQuizzes(_ quizInstances: [QuizInstance]) async
    func presentHostingQuizzes(_ quizInstances: [QuizInstance]) async
    func presentError(_ error: UserServiceError) async
    func presentProfileScreen() async
    func presentJoinQuizSuccess() async
    func presentJoinQuizError() async
}
