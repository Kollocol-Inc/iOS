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

            let tabs = makeTabs()
            tabBarController.setViewControllers(tabs, animated: false)
            configureTabBarAppearance()

            navigationController.setViewControllers([tabBarController], animated: true)
        }

    // MARK: - Private Methods
    private func finish() {
        onFinish()
    }

    private func makeTabs() -> [UIViewController] {
        let mainVC = MainAssembly.build(router: self)
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

        let profileVC = ProfileAssembly.build(router: self)
        let profileNav = makeTabNavigationController(
            root: profileVC,
            tab: .profile
        )
        profileNavController = profileNav

        return [mainNav, groupsNav, myQuizzesNav, profileNav]
    }

    private func makeTabNavigationController(root: UIViewController, tab: Tab) -> UINavigationController {
        let nav = UINavigationController(rootViewController: root)

        nav.tabBarItem = UITabBarItem(
            title: tab.title,
            image: UIImage(systemName: tab.imageName),
            selectedImage: UIImage(systemName: tab.selectedImageName)
        )

        return nav
    }

    private func configureTabBarAppearance() {
        tabBarController.tabBar.tintColor = .accentPrimary
        tabBarController.tabBar.unselectedItemTintColor = .textSecondary
    }
}

// MARK: - AuthRouting
extension MainCoordinator: MainRouting {
    
}

// MARK: - MyQuizzesRouting
extension MainCoordinator: GroupsRouting {

}

// MARK: - MyQuizzesRouting
extension MainCoordinator: MyQuizzesRouting {

}

// MARK: - ProfileRouting
extension MainCoordinator: ProfileRouting {
    
}

@MainActor
protocol MainRouting: AnyObject {
    
}

@MainActor
protocol GroupsRouting: AnyObject {

}

@MainActor
protocol MyQuizzesRouting: AnyObject {

}

@MainActor
protocol ProfileRouting: AnyObject {

}
