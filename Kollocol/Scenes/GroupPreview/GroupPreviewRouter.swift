//
//  GroupPreviewRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import Foundation

@MainActor
final class GroupPreviewRouter: GroupPreviewPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: GroupPreviewViewController?

    private let router: GroupsRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: GroupsRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentGroup(_ data: GroupPreviewModels.ViewData) async {
        await view?.displayGroup(data)
    }

    func presentParticipants(_ data: GroupPreviewModels.ParticipantsViewData) async {
        await view?.displayParticipants(data)
    }

    func closePreview() async {
        await router.dismissGroupPreviewScreen()
    }

    func presentServiceError(_ error: GroupServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }
}
