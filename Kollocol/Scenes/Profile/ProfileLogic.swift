//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class ProfileLogic: ProfileInteractor {
    // MARK: - Constants
    private let presenter: ProfilePresenter
    private let userService: UserService
    private let sessionManager: SessionManager

    // MARK: - Lifecycle
    init(
        presenter: ProfilePresenter,
        userService: UserService,
        sessionManager: SessionManager
    ) {
        self.presenter = presenter
        self.userService = userService
        self.sessionManager = sessionManager
    }

    // MARK: - Methods
    func fetchUserProfile() async {
        do {
            let user = try await userService.getUserProfile()
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentServiceError(UserServiceError.wrap(error))
        }
    }

    func logout() async {
        await presenter.presentLogoutConfirmation { [weak self] in
            Task { [weak self] in
                await self?.performLogout()
            }
        }
    }

    // MARK: - Private Methods
    private func performLogout() async {
        await sessionManager.forcedLogout()
    }
}
