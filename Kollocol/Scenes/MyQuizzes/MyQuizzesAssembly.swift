//
//  MainAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum MyQuizzesAssembly {
    @MainActor
    static func build(
        router: MyQuizzesRouting
    ) -> UIViewController {
        let presenter = MyQuizzesRouter(router: router)
        let interactor = MyQuizzesLogic(presenter: presenter)
        let view = MyQuizzesViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
