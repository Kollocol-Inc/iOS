//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class GroupsLogic: GroupsInteractor {
    // MARK: - Constants
    private let presenter: GroupsPresenter

    // MARK: - Lifecycle
    init(presenter: GroupsPresenter) {
        self.presenter = presenter
    }
}
