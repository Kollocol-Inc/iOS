//
//  GetNotifications.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import Foundation

struct GetNotifications: Endpoint {
    typealias Response = NotificationsSettingsDTO

    var method: HTTPMethod { .get }
    var path: String { "/users/me/notifications" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
