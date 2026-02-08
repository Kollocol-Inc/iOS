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
        startAuth()
    }
    
    // MARK: - Private Methods
    private func startAuth() {
        let auth = AuthCoordinator(
            navigationController: navigationController,
            services: services,
            onFinish: {
                self.activeFlow = nil
                self.startMain()
            }
        )
        activeFlow = auth
        auth.start()
    }
    
    private func startMain() {
        // запускаем основной флоу приложения
    }
}

// MARK: - Services
struct Services {
    let authService: AuthService
}

