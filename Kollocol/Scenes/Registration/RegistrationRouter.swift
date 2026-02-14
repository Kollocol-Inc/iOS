//
//  RegistrationRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class RegistrationRouter: RegistrationPresenter {
    // MARK: - Typealias
    typealias AvatarCropCompletion = @MainActor (UIImage?) -> Void

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
            message: "Произошла ошибка при загрузке аватара"
        )

        await view?.deleteAvatar()
        await view?.unlockFieldsAndButtons()
    }

    func presentDeleteAvatarConfirmation() async {
        await router.showAvatarDeleteConfirmation { [weak self] in
            self?.view?.deleteAvatar()
        }
    }
    
    func presentAvatarCrop(image: UIImage) async {
        await router.showAvatarCrop(image: image) { [weak self] cropped in
            self?.view?.unlockFieldsAndButtons()

            guard let cropped else { return }
            self?.view?.applyCroppedAvatar(cropped)
        }
    }
}
