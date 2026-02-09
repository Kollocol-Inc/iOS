//
//  VerifyCodeAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

enum VerifyCodeAssembly {
    @MainActor
    static func build(
        router: AuthRouting,
        email: String,
        authService: AuthService
    ) -> UIViewController {
        let presenter = VerifyCodeRouter(router: router)
        let interactor = VerifyCodeLogic(presenter: presenter, authService: authService)
        let view = VerifyCodeViewController(interactor: interactor, email: email)
        presenter.view = view
        
        return view
    }
}
