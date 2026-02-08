//
//  StartInteractor.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

actor StartLogic: StartInteractor {
    // MARK: - Constants
    private let presenter: StartPresenter
    private let authService: AuthService
    
    // MARK: - Lifecycle
    init(presenter: StartPresenter, authService: AuthService) {
        self.presenter = presenter
        self.authService = authService
    }
    
    // MARK: - Methods
    func login(with email: String) async {
        do {
            try await authService.login(using: email)
            
            await presenter.presentLoginSuccess()
        } catch {
            await presenter.presentLoginError(AuthServiceError.wrap(error))
        }
    }
}
