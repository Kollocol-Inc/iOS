//
//  RegistrationRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class RegistrationRouter: RegistrationPresenter {
    // MARK: - Properties
    weak var view: RegistrationViewController?
    
    private let router: AuthRouting
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }
    
    // MARK: - Methods
    func presentSuccessfulRegister() async {
        await router.routeToMainFlow()
    }
    
    func presentRegisterError(_ error: UserServiceError) async {
        let message: String
        
        switch error {
            case .offline:
                message = "Нет интернета"
            default:
                message = "Что-то пошло не так"
        }
        
        await router.showError(title: "Ошибка", message: message)
        
        await view?.showError()
    }
    
    func presentDeleteAvatarConfirmation() async {
        await router.showAvatarDeleteConfirmation { [weak self] in
            self?.view?.deleteAvatar()
        }
    }
}
