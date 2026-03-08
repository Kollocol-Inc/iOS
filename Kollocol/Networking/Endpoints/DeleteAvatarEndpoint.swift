//
//  DeleteAvatar.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.02.2026.
//

import Foundation

struct DeleteAvatarEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var method: HTTPMethod { .delete }
    var path: String { "/users/me/avatar/delete" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
