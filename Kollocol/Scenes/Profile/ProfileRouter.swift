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
        let fullName = [user.firstName, user.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        let email = user.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        await view?.displayUserProfile(
            avatarUrl: user.avatarUrl,
            fullName: fullName,
            email: email
        )
    }

    func presentServiceError(_ error: UserServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        await router.showLogoutConfirmation(onConfirm: onConfirm)
    }
}
