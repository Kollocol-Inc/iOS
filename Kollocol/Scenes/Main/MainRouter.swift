//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MainRouter: MainPresenter {
    // MARK: - Properties
    weak var view: MainViewController?
    
    private let router: MainRouting
    
    // MARK: - Lifecycle
    init(router: MainRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentUserProfile(_ user: UserDTO) async {
        let name = [user.firstName, user.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        await view?.displayUserProfile(avatarUrl: user.avatarUrl, name: name)
    }

    func presentError(_ error: UserServiceError) async {
        // TODO: Handle error
    }

    func presentProfileScreen() async {
        await router.routeToProfileScreen()
    }
}
