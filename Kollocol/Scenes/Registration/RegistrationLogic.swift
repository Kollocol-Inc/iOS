//
//  RegistrationLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class RegistrationLogic: RegistrationInteractor {
    // MARK: - Constants
    private let presenter: RegistrationPresenter
    private let userService: UserService
    
    // MARK: - Lifecycle
    init(presenter: RegistrationPresenter, userService: UserService) {
        self.presenter = presenter
        self.userService = userService
    }
    
    // MARK: - Methods
    func register(name: String, surname: String) async {
        do {
            try await userService.register(name: name, surname: surname)
            
            await presenter.presentSuccessfulRegister()
        } catch {
            await presenter.presentRegisterError(UserServiceError.wrap(error))
        }
    }
    
    func requestDeleteAvatarConfirmation() async {
        await presenter.presentDeleteAvatarConfirmation()
    }
}
