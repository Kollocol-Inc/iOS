//
//  DeleteNotificationsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct DeleteNotificationsEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let request: NotificationIDsRequestDTO

    var method: HTTPMethod { .delete }
    var path: String { "/notifications/delete" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
