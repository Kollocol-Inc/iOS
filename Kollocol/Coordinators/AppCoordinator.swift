//
//  AppCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

@MainActor
final class AppCoordinator {
    // MARK: - Properties
    private let navigationController: UINavigationController
    private let services: Services
    private var activeFlow: AnyObject?

    // MARK: - Lifecycle
    init(navigationController: UINavigationController, services: Services) {
        self.navigationController = navigationController
        self.services = services
    }

    // MARK: - Methods
    func start() {
        Task { [weak self] in
            guard let self else { return }

            let hasToken = await services.tokenStore.refreshToken() != nil
            let isRegistered = services.udService.isRegistered

            if hasToken, isRegistered {
                startMain()
            } else if hasToken, !isRegistered {
                startAuth(entry: .registration)
            } else {
                startAuth(entry: .start)
            }
        }
    }
    
    // MARK: - Private Methods
    private func startAuth(entry: AuthCoordinator.Entry) {
        let auth = AuthCoordinator(
            navigationController: navigationController,
            services: services,
            entry: entry,
            onFinish: { [weak self] in
                guard let self else { return }
                self.activeFlow = nil
                self.startMain()
            }
        )
        activeFlow = auth
        auth.start()
    }
    
    private func startMain() {
        let main = MainCoordinator(
            navigationController: navigationController,
            services: services,
            onFinish: {
                self.activeFlow = nil
            }
        )
        activeFlow = main
        main.start()
    }
}

// MARK: - Services
struct Services {
    let authService: AuthService
    let sessionManager: SessionManager
    let tokenStore: any TokenStoring
    let udService: UserDefaultsService
    let userService: UserService
}
