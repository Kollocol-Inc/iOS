//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MainLogic: MainInteractor {
    // MARK: - Constants
    private let presenter: MainPresenter
    private let userService: UserService

    // MARK: - Lifecycle
    init(presenter: MainPresenter, userService: UserService) {
        self.presenter = presenter
        self.userService = userService
    }

    // MARK: - Methods
    func fetchUserProfile() async {
        do {
            let user = try await userService.getUserProfile()
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentError(UserServiceError.wrap(error))
        }
    }

    func routeToProfileScreen() async {
        await presenter.presentProfileScreen()
    }
}
