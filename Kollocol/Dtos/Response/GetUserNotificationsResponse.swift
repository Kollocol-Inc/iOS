//
//  GetUserNotificationsResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct GetUserNotificationsResponse: Decodable {
    let notifications: [UserNotificationDTO]
    let total: Int?
}

// MARK: - GetUserNotificationsResponse -> UserNotificationsPage
extension GetUserNotificationsResponse {
    func toDomain() -> UserNotificationsPage {
        return UserNotificationsPage(
            notifications: self.notifications.map { $0.toDomain() },
            total: self.total
        )
    }
}
