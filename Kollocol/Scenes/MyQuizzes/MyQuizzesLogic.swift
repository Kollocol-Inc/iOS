//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MyQuizzesLogic: MyQuizzesInteractor {
    // MARK: - Constants
    private let presenter: MyQuizzesPresenter

    // MARK: - Lifecycle
    init(presenter: MyQuizzesPresenter) {
        self.presenter = presenter
    }
}
