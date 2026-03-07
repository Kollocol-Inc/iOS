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
        router: MyQuizzesRouting,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = MyQuizzesRouter(router: router)
        let interactor = MyQuizzesLogic(presenter: presenter, quizService: quizService)
        let view = MyQuizzesViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
