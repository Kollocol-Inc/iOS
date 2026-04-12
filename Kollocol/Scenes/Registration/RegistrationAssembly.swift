//
//  RegistrationAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum RegistrationAssembly {
    @MainActor
    static func build(
        router: AuthRouting,
        userService: UserService,
        sessionManager: SessionManager
    ) -> UIViewController {
        let presenter = RegistrationRouter(router: router)
        let interactor = RegistrationLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager
        )
        let view = RegistrationViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
