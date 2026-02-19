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
        
        await view?.unlockFieldsAndButtons()
    }

    func presentAvatarUploadError() async {
        await router.showError(
            title: "Ошибка",
            message: "Произошла ошибка при загрузке аватара, выберите другую или попробуйте позже"
        )

        await view?.resetAvatarAfterUploadError()
    }

    func presentDeleteAvatarConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        await router.showAvatarDeleteConfirmation {
            onConfirm()
        }
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
        await router.showAvatarCrop(image: image) { cropped in
            onFinish(cropped)
        }
    }
}
