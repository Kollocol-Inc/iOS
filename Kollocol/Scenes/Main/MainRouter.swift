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
}
