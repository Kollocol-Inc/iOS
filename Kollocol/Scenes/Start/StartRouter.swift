//
//  StartPresenter.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

@MainActor
final class StartRouter: StartPresenter {
    // MARK: - Variables
    weak var view: StartViewController?
    
    private let router: AuthRouting
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentLoginSuccess() async {
        
    }
    
    func presentLoginError(_ error: AuthServiceError) async {
        let message: String
        
        switch error {
            case .invalidEmail:
                message = "Неверный формат почты"
            case .tooManyRequests:
                message = "Слишком много попыток"
            case .offline:
                message = "Нет интернета"
            default:
                message = "Что-то пошло не так"
        }
        
        await router.showError(title: "Ошибка", message: message)
        
        await view?.showError()
    }
}
