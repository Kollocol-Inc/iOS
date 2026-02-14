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
        router: ProfileRouting,
        sessionManager: SessionManager
    ) -> UIViewController {
        let presenter = ProfileRouter(router: router)
        let interactor = ProfileLogic(presenter: presenter, sessionManager: sessionManager)
        let view = ProfileViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
