//
//  MainAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum ProfileAssembly {
    @MainActor
    static func build(
        router: MainRouting
    ) -> UIViewController {
        let presenter = ProfileRouter(router: router)
        let interactor = ProfileLogic(presenter: presenter)
        let view = ProfileViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
