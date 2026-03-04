//
//  VerifyCodeRouter.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

@MainActor
final class VerifyCodeRouter: VerifyCodePresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: VerifyCodeViewController?
    private let router: AuthRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }
    
    // MARK: - Methods
    func presentSuccessfulVerifying(isRegistered: Bool) async {
        if isRegistered {
            await router.routeToMainFlow()
        } else {
            await router.routeToRegistration()
        }
    }
    
    func presentVerifyingError(_ error: AuthServiceError) async {
        await presentServiceError(error)
        await view?.showCodeValidationFailed()
    }

    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        guard useCase == .generic else { return nil }
        guard let authError = error as? AuthServiceError else { return nil }
        guard case .tooManyRequests = authError else { return nil }

        return "Слишком много попыток ввода кода. Попробуйте еще раз через несколько минут"
    }
}
