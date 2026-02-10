//
//  AuthCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

@MainActor
final class AuthCoordinator {
    // MARK: - Enum
    enum Entry {
        case start
        case registration
    }
    
    // MARK: - Properties
    private let navigationController: UINavigationController
    private let services: Services
    private let entry: Entry
    private let onFinish: () -> Void
    
    // MARK: - Lifecycle
    init(
        navigationController: UINavigationController,
        services: Services,
        entry: Entry,
        onFinish: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.services = services
        self.entry = entry
        self.onFinish = onFinish
    }
    
    // MARK: - Methods
    func start() {
//        let vc = RegistrationAssembly.build(
//            router: self,
//            userService: services.userService
//        )
//        navigationController.setViewControllers([vc], animated: true)
        
        switch entry {
        case .start:
            let vc = StartAssembly.build(
                router: self,
                authService: services.authService
            )
            navigationController.setViewControllers([vc], animated: true)

        case .registration:
            let vc = RegistrationAssembly.build(
                router: self,
                userService: services.userService
            )
            navigationController.setViewControllers([vc], animated: true)
        }
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
        let vc = VerifyCodeAssembly.build(
            router: self,
            email: email,
            authService: services.authService
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func routeToRegistration() {
        let vc = RegistrationAssembly.build(
            router: self,
            userService: services.userService
        )
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showAvatarDeleteConfirmation(onConfirm: @escaping @MainActor () -> Void) {
        let alert = UIAlertController(
            title: "Внимание!",
            message: "Вы уверены, что хотите удалить фото? Отменить это действие невозможно",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Отменить", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
            onConfirm()
        })

        navigationController.visibleViewController?.present(alert, animated: true)
    }
    
    func routeToMainFlow() {
        finish()
    }
}

// MARK: - AuthRouting
@MainActor
protocol AuthRouting: AnyObject {
    func showError(title: String, message: String)
    func routeToVerifyCode(email: String)
    func routeToRegistration()
    func showAvatarDeleteConfirmation(onConfirm: @escaping @MainActor () -> Void)
    func routeToMainFlow()
}
