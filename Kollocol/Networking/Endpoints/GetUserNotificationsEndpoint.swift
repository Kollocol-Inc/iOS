//
//  GetUserNotificationsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct GetUserNotificationsEndpoint: Endpoint {
    typealias Response = GetUserNotificationsResponse

    let limit: Int
    let offset: Int

    var method: HTTPMethod { .get }
    var path: String { "/notifications" }
    var query: [URLQueryItem] {
        [
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
    }
    var body: AnyEncodable? { nil }
}
