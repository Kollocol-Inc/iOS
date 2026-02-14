//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class MyQuizzesRouter: MyQuizzesPresenter {
    // MARK: - Properties
    weak var view: MyQuizzesViewController?

    private let router: MyQuizzesRouting

    // MARK: - Lifecycle
    init(router: MyQuizzesRouting) {
        self.router = router
    }
}
