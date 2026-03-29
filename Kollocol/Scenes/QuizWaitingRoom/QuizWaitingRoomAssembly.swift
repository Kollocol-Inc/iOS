//
//  QuizWaitingRoomAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

enum QuizWaitingRoomAssembly {
    @MainActor
    static func build(
        router: QuizWaitingRoomRouting,
        quizParticipationService: QuizParticipationService,
        initialData: QuizWaitingRoomModels.InitialData
    ) -> UIViewController {
        let presenter = QuizWaitingRoomRouter(router: router)
        let interactor = QuizWaitingRoomLogic(
            presenter: presenter,
            quizParticipationService: quizParticipationService
        )
        let view = QuizWaitingRoomViewController(
            interactor: interactor,
            initialData: initialData
        )
        presenter.view = view

        return view
    }
}
