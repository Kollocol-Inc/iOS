//
//  VerifyCodeRouter.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

@MainActor
final class VerifyCodeRouter: VerifyCodePresenter {
    // MARK: - Properties
    weak var view: VerifyCodeViewController?
    private let router: AuthRouting
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }
    
    // MARK: - Methods
    func presentSuccessfulVerifying() async {
        print("SUCCESS")
    }
    
    func presentVerifyingError(_ error: AuthServiceError) async {
        let message: String
        
        switch error {
            case .tooManyRequests:
                message = "Слишком много попыток ввода кода. Попробуйте еще раз через несколько минут"
            case .offline:
                message = "Нет интернета"
            default:
                message = "Что-то пошло не так"
        }
        
        await router.showError(title: "Ошибка", message: message)
        
        await view?.showCodeValidationFailed()
    }
}
