//
//  MainAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum GroupsAssembly {
    @MainActor
    static func build(
        router: GroupsRouting
    ) -> UIViewController {
        let presenter = GroupsRouter(router: router)
        let interactor = GroupsLogic(presenter: presenter)
        let view = GroupsViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
