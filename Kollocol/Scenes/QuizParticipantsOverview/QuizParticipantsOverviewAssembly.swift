//
//  QuizParticipantsOverviewAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

enum QuizParticipantsOverviewAssembly {
    @MainActor
    static func build(
        router: QuizParticipantsOverviewRouting,
        initialData: QuizParticipantsOverviewModels.InitialData,
        quizService: QuizService
    ) -> UIViewController {
        let presenter = QuizParticipantsOverviewRouter(router: router)
        let interactor = QuizParticipantsOverviewLogic(
            presenter: presenter,
            quizService: quizService,
            instanceId: initialData.instanceId,
            quizTitle: initialData.quizTitle
        )
        let view = QuizParticipantsOverviewViewController(
            interactor: interactor,
            initialData: initialData
        )
        presenter.view = view

        return view
    }
}
