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
        groupId: String? = nil,
        quizService: QuizService,
        groupService: GroupService,
        quizParticipationService: QuizParticipationService
    ) -> UIViewController {
        let presenter = StartQuizRouter(router: router)
        let interactor = StartQuizLogic(
            presenter: presenter,
            quizService: quizService,
            groupService: groupService,
            quizParticipationService: quizParticipationService,
            template: template
        )
        let view = StartQuizViewController(
            interactor: interactor,
            initialData: .init(
                groupId: groupId,
                title: template.title ?? "",
                quizType: template.quizType
            )
        )
        presenter.view = view

        return view
    }
}
