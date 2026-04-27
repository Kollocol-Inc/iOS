//
//  RegistrationRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class RegistrationRouter: RegistrationPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: RegistrationViewController?
    
    private let router: AuthRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }
    
    // MARK: - Lifecycle
    init(router: AuthRouting) {
        self.router = router
    }
    
    // MARK: - Methods
    func presentSuccessfulRegister() async {
        await router.routeToMainFlow()
    }
    
    func presentRegisterError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .registrationSubmit)
        await view?.unlockFieldsAndButtons()
    }

    func presentAvatarUploadError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .avatarUpload)
        await view?.resetAvatarAfterUploadError()
    }

    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        guard let userServiceError = error as? UserServiceError else { return nil }

        switch useCase {
        case .registrationSubmit:
            if userServiceError == .badRequest {
                return "registrationFailedError".localized
            }
            return nil

        case .avatarUpload:
            if userServiceError == .badRequest {
                return "avatarTooLargeError".localized
            }
            return "avatarUploadFailedError".localized

        default:
            return nil
        }
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
