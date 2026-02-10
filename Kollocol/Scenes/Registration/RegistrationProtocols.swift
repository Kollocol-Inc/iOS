//
//  RegistrationProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol RegistrationInteractor {
    func register(name: String, surname: String) async
    func requestDeleteAvatarConfirmation() async
}

protocol RegistrationPresenter {
    func presentSuccessfulRegister() async
    func presentRegisterError(_ error: UserServiceError) async
    func presentDeleteAvatarConfirmation() async
}
