//
//  TemplateCreatingAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import UIKit

enum TemplateCreatingAssembly {
    @MainActor
    static func build(
        router: TemplateCreatingRouting,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = TemplateCreatingRouter(router: router)
        let interactor = TemplateCreatingLogic(presenter: presenter, quizService: quizService)
        let view = TemplateCreatingViewController(interactor: interactor)
        presenter.view = view

        return view
    }
}
