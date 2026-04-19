//
//  QuizParticipantReviewAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

enum QuizParticipantReviewAssembly {
    @MainActor
    static func build(
        router: QuizParticipantReviewRouting,
        initialData: QuizParticipantReviewModels.InitialData,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = QuizParticipantReviewRouter(router: router)
        let interactor = QuizParticipantReviewLogic(
            presenter: presenter,
            quizService: quizService,
            initialData: initialData
        )
        let view = QuizParticipantReviewViewController(
            interactor: interactor,
            initialData: initialData
        )
        presenter.view = view

        return view
    }
}
