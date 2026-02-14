//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class GroupsRouter: GroupsPresenter {
    // MARK: - Properties
    weak var view: GroupsViewController?

    private let router: GroupsRouting

    // MARK: - Lifecycle
    init(router: GroupsRouting) {
        self.router = router
    }
}
