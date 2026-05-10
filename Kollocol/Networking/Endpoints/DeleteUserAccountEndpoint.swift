//
//  DeleteUserAccountEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

struct DeleteUserAccountEndpoint: Endpoint {
    typealias Response = EmptyResponse

    var method: HTTPMethod { .delete }
    var path: String { "/users/me" }
    var body: AnyEncodable? { nil }
}
