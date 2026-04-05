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
        mlService: MLService,
        template: QuizTemplate? = nil,
        prefilledTitle: String? = nil,
        questions: [Question]? = nil
    ) -> UIViewController {
        let presenter = TemplateCreatingRouter(router: router)
        let interactor = TemplateCreatingLogic(
            presenter: presenter,
            quizService: quizService,
            mlService: mlService
        )
        let view = TemplateCreatingViewController(
            interactor: interactor,
            template: template,
            prefilledTitle: prefilledTitle,
            questions: questions
        )
        presenter.view = view

        return view
    }
}
