//
//  VerifyCodeLogic.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

final class VerifyCodeLogic: VerifyCodeInteractor {
    // MARK: - Constants
    private let presenter: VerifyCodePresenter
    private let authService: AuthService
    
    // MARK: - Lifecycle
    init(presenter: VerifyCodePresenter, authService: AuthService) {
        self.presenter = presenter
        self.authService = authService
    }
    
    // MARK: - Methods
    func verify(code: String, with email: String) async {
        do {
            try await authService.verify(code: code, with: email)
            
            await presenter.presentSuccessfulVerifying()
        } catch {
            await presenter.presentVerifyingError(AuthServiceError.wrap(error))
        }
    }
}
