//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class ProfileLogic: ProfileInteractor {
    // MARK: - Constants
    private let presenter: ProfilePresenter
    
    // MARK: - Lifecycle
    init(presenter: ProfilePresenter) {
        self.presenter = presenter
    }
}
