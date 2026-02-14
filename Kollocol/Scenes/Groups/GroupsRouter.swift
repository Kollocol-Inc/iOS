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

    private let router: MainRouting
    
    // MARK: - Lifecycle
    init(router: MainRouting) {
        self.router = router
    }
}
