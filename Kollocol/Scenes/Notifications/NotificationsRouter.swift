//
//  NotificationsRouter.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import Foundation

@MainActor
final class NotificationsRouter: NotificationsPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: NotificationsViewController?

    private let router: MainRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: MainRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentNotifications(_ notifications: [NotificationsModels.NotificationViewData]) async {
        view?.displayNotifications(notifications)
    }

    func presentServiceError(_ error: any UserFacingError) async {
        await presentServiceError(error, useCase: .generic)
    }
}
