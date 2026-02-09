//
//  StartProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

protocol StartInteractor: Actor {
    func login(with email: String) async
}

protocol StartPresenter {
    func presentLoginSuccess(email: String) async
    func presentLoginError(_ error: AuthServiceError) async
}
