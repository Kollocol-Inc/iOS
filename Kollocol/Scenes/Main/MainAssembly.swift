//
//  MainAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum MainAssembly {
    @MainActor
    static func build(
        router: MainRouting
    ) -> UIViewController {
        let presenter = MainRouter(router: router)
        let interactor = MainLogic(presenter: presenter)
        let view = MainViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
