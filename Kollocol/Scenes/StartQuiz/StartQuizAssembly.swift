//
//  StartQuizAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import UIKit

enum StartQuizAssembly {
    @MainActor
    static func build(
        router: StartQuizRouting,
        template: QuizTemplate,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = StartQuizRouter(router: router)
        let interactor = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            template: template
        )
        let view = StartQuizViewController(
            interactor: interactor,
            initialData: .init(
                title: template.title ?? "",
                quizType: template.quizType
            )
        )
        presenter.view = view

        return view
    }
}
