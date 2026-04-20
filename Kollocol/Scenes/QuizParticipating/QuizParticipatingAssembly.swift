//
//  QuizParticipatingAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

enum QuizParticipatingAssembly {
    @MainActor
    static func build(
        router: QuizParticipatingRouting,
        quizParticipationService: QuizParticipationService,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = QuizParticipatingRouter(router: router)
        let interactor = QuizParticipatingLogic(
            presenter: presenter,
            quizParticipationService: quizParticipationService,
            quizService: quizService
        )
        let view = QuizParticipatingViewController(interactor: interactor)
        presenter.view = view

        return view
    }
}
