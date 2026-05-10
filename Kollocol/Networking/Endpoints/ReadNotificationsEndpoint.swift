//
//  ReadNotificationsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct ReadNotificationsEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let request: NotificationIDsRequestDTO

    var method: HTTPMethod { .put }
    var path: String { "/notifications/read" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
