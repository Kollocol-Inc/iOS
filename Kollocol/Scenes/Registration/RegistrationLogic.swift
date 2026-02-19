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

    // MARK: - Lifecycle
    init(presenter: RegistrationPresenter, userService: UserService) {
        self.presenter = presenter
        self.userService = userService
    }
    
    // MARK: - Methods
    func register(name: String, surname: String, avatarData: Data?) async {
        if let avatarData {
            do {
                try await userService.uploadAvatar(data: avatarData)
            } catch {
                await presenter.presentAvatarUploadError()
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
}
