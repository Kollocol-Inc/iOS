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
        userService: UserService
    ) -> UIViewController {
        let presenter = RegistrationRouter(router: router)
        let interactor = RegistrationLogic(presenter: presenter, userService: userService)
        let view = RegistrationViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
