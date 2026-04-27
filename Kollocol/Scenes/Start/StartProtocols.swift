//
//  StartProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

protocol StartInteractor: Actor {
    func login(with email: String) async
    func fetchLanguageOption() async
    func updateLanguageOption(_ option: StartModels.LanguageOption) async
}

protocol StartPresenter {
    func presentLoginSuccess(email: String) async
    func presentLoginError(_ error: AuthServiceError) async
    func presentLanguageOption(_ option: StartModels.LanguageOption) async
}
