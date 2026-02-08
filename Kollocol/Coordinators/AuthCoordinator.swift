//
//  AuthCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

@MainActor
final class AuthCoordinator {
    // MARK: - Properties
    private let navigationController: UINavigationController
    private let services: Services
    private let onFinish: () -> Void
    
    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        services: Services,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.services = services
        self.onFinish = onFinish
    }
    
    // MARK: - Methods
    func start() {
        let vc = StartAssembly.build(router: self, authService: services.authService)
        navigationController.setViewControllers([vc], animated: false)
    }
    
    // MARK: - Private Methods
    private func finish() {
        onFinish()
    }
}

// MARK: - AuthRouting
extension AuthCoordinator: AuthRouting {
    func showError(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ОК", style: .default))
        navigationController.visibleViewController?.present(alert, animated: true)
    }
    
    func routeToVerifyCode(email: String) {
        //
    }
    
    
}

@MainActor
protocol AuthRouting: AnyObject {
    func showError(title: String, message: String)
    func routeToVerifyCode(email: String)
}
