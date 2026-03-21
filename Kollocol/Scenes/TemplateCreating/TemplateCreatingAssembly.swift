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
        template: QuizTemplate? = nil,
        questions: [Question]? = nil
    ) -> UIViewController {
        let presenter = TemplateCreatingRouter(router: router)
        let interactor = TemplateCreatingLogic(presenter: presenter, quizService: quizService)
        let view = TemplateCreatingViewController(
            interactor: interactor,
            template: template,
            questions: questions
        )
        presenter.view = view

        return view
    }
}
