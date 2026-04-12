//
//  RegistrationLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class RegistrationLogic: RegistrationInteractor {
    // MARK: - Constants
    private let presenter: RegistrationPresenter
    private let userService: UserService
    private let sessionManager: SessionManager

    // MARK: - Lifecycle
    init(
        presenter: RegistrationPresenter,
        userService: UserService,
        sessionManager: SessionManager
    ) {
        self.presenter = presenter
        self.userService = userService
        self.sessionManager = sessionManager
    }
    
    // MARK: - Methods
    func register(name: String, surname: String, avatarData: Data?) async {
        if let avatarData {
            do {
                try await userService.uploadAvatar(data: avatarData)
            } catch {
                await presenter.presentAvatarUploadError(UserServiceError.wrap(error))
                return
            }
        }

        do {
            try await userService.register(name: name, surname: surname)
            await presenter.presentSuccessfulRegister()
        } catch {
            await presenter.presentRegisterError(UserServiceError.wrap(error))
        }
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
        await presenter.presentAvatarCrop(image: image, onFinish: onFinish)
    }

    func presentAvatarDeleteConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        await presenter.presentDeleteAvatarConfirmation(onConfirm: onConfirm)
    }

    func cancelRegistration() async {
        await sessionManager.forcedLogout()
    }
}
