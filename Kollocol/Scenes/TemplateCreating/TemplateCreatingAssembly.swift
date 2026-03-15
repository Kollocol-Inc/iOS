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
        quizService: QuizService,
        questions: [Question]? = nil
    ) -> UIViewController {
        let presenter = TemplateCreatingRouter(router: router)
        let interactor = TemplateCreatingLogic(presenter: presenter, quizService: quizService)
        let view = TemplateCreatingViewController(interactor: interactor, questions: questions)
        presenter.view = view

        return view
    }
}
