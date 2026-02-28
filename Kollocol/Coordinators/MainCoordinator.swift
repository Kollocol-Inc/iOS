//
//  MainCoordinator.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MainCoordinator {
    // MARK: - Constants
    private enum Tab {
        case main
        case groups
        case myQuizzes
        case profile

        var title: String {
            switch self {
            case .main: return "Главная"
            case .groups: return "Группы"
            case .myQuizzes: return "Мои квизы"
            case .profile: return "Профиль"
            }
        }

        var imageName: String {
            switch self {
            case .main: return "house"
            case .groups: return "person.2"
            case .myQuizzes: return "gamecontroller"
            case .profile: return "person"
            }
        }

        var selectedImageName: String {
            switch self {
            case .main: return "house.fill"
            case .groups: return "person.2.fill"
            case .myQuizzes: return "gamecontroller.fill"
            case .profile: return "person.fill"
            }
        }
    }

    // MARK: - Properties
    private let tabBarController = UITabBarController()
    private let tabBarDelegateProxy = TabBarSlideDelegateProxy()
    private let navigationController: UINavigationController
    private let services: Services
    private let onFinish: () -> Void

    private var mainNavController: UINavigationController?
    private var groupsNavController: UINavigationController?
    private var myQuizzesNavController: UINavigationController?
    private var profileNavController: UINavigationController?

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
        navigationController.setNavigationBarHidden(true, animated: false)

        tabBarController.delegate = tabBarDelegateProxy

        let tabs = makeTabs()
        tabBarController.setViewControllers(tabs, animated: false)

        navigationController.setViewControllers([tabBarController], animated: true)
    }

    // MARK: - Private Methods
    private func finish() {
        onFinish()
    }

    private func makeTabs() -> [UIViewController] {
        let mainVC = MainAssembly.build(router: self, userService: services.userService)
        let mainNav = makeTabNavigationController(
            root: mainVC,
            tab: .main
        )
        mainNavController = mainNav

        let groupsVC = GroupsAssembly.build(router: self)
        let groupsNav = makeTabNavigationController(
            root: groupsVC,
            tab: .groups
        )
        groupsNavController = groupsNav

        let myQuizzesVC = MyQuizzesAssembly.build(router: self)
        let myQuizzesNav = makeTabNavigationController(
            root: myQuizzesVC,
            tab: .myQuizzes
        )
        myQuizzesNavController = myQuizzesNav

        let profileVC = ProfileAssembly.build(router: self, sessionManager: services.sessionManager)
        let profileNav = makeTabNavigationController(
            root: profileVC,
            tab: .profile
        )
        profileNavController = profileNav

        return [mainNav, groupsNav, myQuizzesNav, profileNav]
    }

    private func makeTabNavigationController(root: UIViewController, tab: Tab) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)

        let normalImage = UIImage(systemName: tab.imageName)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)

        let selectedImage = UIImage(systemName: tab.selectedImageName)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        let item = UITabBarItem(
            title: nil,
            image: normalImage,
            selectedImage: selectedImage
        )

        item.setTitleTextAttributes([.foregroundColor: UIColor.textSecondary], for: .normal)
        item.setTitleTextAttributes([.foregroundColor: UIColor.accentPrimary], for: .selected)

        nav.tabBarItem = item
        return nav
    }

    private func topMostViewController() -> UIViewController? {
        func resolve(from vc: UIViewController?) -> UIViewController? {
            if let presented = vc?.presentedViewController {
                return resolve(from: presented)
            }
            if let nav = vc as? UINavigationController {
                return resolve(from: nav.visibleViewController)
            }
            if let tab = vc as? UITabBarController {
                return resolve(from: tab.selectedViewController)
            }
            return vc
        }

        return resolve(from: navigationController)
    }
}

// MARK: - AlertPresenting
extension MainCoordinator: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        topMostViewController()?.present(alert, animated: true)
    }
}

// MARK: - AuthRouting
extension MainCoordinator: MainRouting {
    func routeToProfileScreen() {
        tabBarController.selectedIndex = 3
    }
}

// MARK: - MyQuizzesRouting
extension MainCoordinator: GroupsRouting {

}

// MARK: - MyQuizzesRouting
extension MainCoordinator: MyQuizzesRouting {

}

// MARK: - ProfileRouting
extension MainCoordinator: ProfileRouting {
    func showLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) {
        showConfirmationAlert(
            title: "Выход из аккаунта",
            message: "Вы уверены, что хотите выйти из аккаунта?",
            cancelTitle: "Отмена",
            confirmTitle: "Выход",
            confirmStyle: .destructive,
            onConfirm: onConfirm
        )
    }
}

@MainActor
protocol MainRouting: AnyObject {
    func routeToProfileScreen()
}

@MainActor
protocol GroupsRouting: AnyObject {

}

@MainActor
protocol MyQuizzesRouting: AnyObject {

}

@MainActor
protocol ProfileRouting: AnyObject {
    func showLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void)
}
