//
//  AuthCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit
import Mantis
import PhotosUI
import ObjectiveC

@MainActor
final class AuthCoordinator {
    // MARK: - Enum
    enum Entry {
        case start
        case registration
    }

    private enum AssociatedKeys {
        static var avatarCropHandlerKey: UInt8 = 0
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
    
    private func presentSafely(_ viewController: UIViewController) {
        if let presented = navigationController.presentedViewController {
            let shouldDismissFirst =
                presented is PHPickerViewController ||
                presented is UIImagePickerController ||
                presented.isBeingDismissed ||
                presented.view.window == nil

            if shouldDismissFirst {
                navigationController.dismiss(animated: true) { [weak self] in
                    guard let self else { return }
                    self.navigationController.present(viewController, animated: true)
                }
                return
            }
        }

        navigationController.present(viewController, animated: true)
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
    
    func showAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        config.cropViewConfig.cropShapeType = .circle(maskOnly: true)
        config.cropViewConfig.showAttachedRotationControlView = false

        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen

        let handler = AvatarCropHandler(onFinish: onFinish)
        cropViewController.delegate = handler

        objc_setAssociatedObject(
            cropViewController,
            &AssociatedKeys.avatarCropHandlerKey,
            handler,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        presentSafely(cropViewController)
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
    func showAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void)
    func routeToMainFlow()
}
