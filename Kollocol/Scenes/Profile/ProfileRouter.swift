//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class ProfileRouter: ProfilePresenter {
    // MARK: - Properties
    weak var view: ProfileViewController?

    private let router: ProfileRouting

    // MARK: - Lifecycle
    init(router: ProfileRouting) {
        self.router = router
    }
}
