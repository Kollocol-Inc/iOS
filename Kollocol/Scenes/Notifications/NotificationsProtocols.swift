//
//  NotificationsProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import Foundation

@MainActor
protocol NotificationsInteractor {
    func handleViewDidLoad() async
    func handleNotificationWillDisplay(notificationId: String) async
    func handleInviteAction(
        notificationId: String,
        action: NotificationsModels.InviteAction
    ) async
}

@MainActor
protocol NotificationsPresenter {
    func presentNotifications(_ notifications: [NotificationsModels.NotificationViewData]) async
    func presentServiceError(_ error: any UserFacingError) async
}
