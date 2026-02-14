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
    private let sessionManager: SessionManager

    // MARK: - Lifecycle
    init(presenter: ProfilePresenter, sessionManager: SessionManager) {
        self.presenter = presenter
        self.sessionManager = sessionManager
    }

    // MARK: - Methods
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
