//
//  StartPresenter.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

@MainActor
final class StartRouter: StartPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: StartViewController?
    
    private let router: AuthRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentLoginSuccess(email: String) async {
        await router.routeToVerifyCode(email: email)
    }
    
    func presentLoginError(_ error: AuthServiceError) async {
        await presentServiceError(error)
        await view?.showError()
    }

    func presentLanguageOption(_ option: StartModels.LanguageOption) async {
        await view?.displayLanguageOption(option)
    }
}
