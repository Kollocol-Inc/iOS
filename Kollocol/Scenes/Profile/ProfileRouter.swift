//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class ProfileRouter: ProfilePresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: ProfileViewController?

    private let router: ProfileRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: ProfileRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentUserProfile(_ user: UserDTO) async {
        let firstName = user.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let lastName = user.lastName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        await view?.displayUserProfile(
            avatarUrl: user.avatarUrl,
            firstName: firstName,
            lastName: lastName,
            email: email
        )
    }

    func presentNotificationsSettings(_ settings: ProfileModels.NotificationsSettings) async {
        await view?.displayNotificationsSettings(settings)
    }

    func presentThemeOption(_ option: ProfileModels.ThemeOption) async {
        await view?.displayThemeOption(option)
    }

    func presentLanguageOption(_ option: ProfileModels.LanguageOption) async {
        await view?.displayLanguageOption(option)
    }

    func presentProfileUpdateError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentAvatarUploadError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .avatarUpload)
    }

    func presentAvatarDeleteError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
        await router.showAvatarCrop(image: image, onFinish: onFinish)
    }

    func presentServiceError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        await router.showLogoutConfirmation(onConfirm: onConfirm)
    }

    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        guard let userServiceError = error as? UserServiceError else { return nil }

        switch useCase {
        case .avatarUpload:
            if userServiceError == .badRequest {
                return "avatarUploadTooLargeError".localized
            }
            return "avatarUploadGenericError".localized

        default:
            return nil
        }
    }
}
