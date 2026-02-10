//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MainLogic: MainInteractor {
    // MARK: - Constants
    private let presenter: MainPresenter
    
    // MARK: - Lifecycle
    init(presenter: MainPresenter) {
        self.presenter = presenter
    }
}
