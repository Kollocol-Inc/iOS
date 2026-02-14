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

    private var avatarUpload: RegistrationModels.AvatarUpload?

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

    func openAvatarCrop(with image: UIImage) async {
        let prepared = await Task.detached(priority: .userInitiated) {
            RegistrationModels.AvatarImageProcessor.prepareForCropping(image)
        }.value

        await presenter.presentAvatarCrop(image: prepared)
    }

    func storeAvatar(image: UIImage) async -> UIImage {
        let upload = await Task.detached(priority: .userInitiated) {
            RegistrationModels.AvatarImageProcessor.processForUpload(image)
        }.value

        avatarUpload = upload
        return upload.image
    }

    func clearAvatar() async {
        avatarUpload = nil
    }

    func requestDeleteAvatarConfirmation() async {
        await presenter.presentDeleteAvatarConfirmation()
    }
}
