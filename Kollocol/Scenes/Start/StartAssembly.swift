//
//  StartAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

enum StartAssembly {
    @MainActor
    static func build(
        router: AuthRouting,
        authService: AuthService,
        udService: UserDefaultsService
    ) -> UIViewController {
        let presenter = StartRouter(router: router)
        let interactor = StartLogic(
            presenter: presenter,
            authService: authService,
            udService: udService
        )
        let view = StartViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
