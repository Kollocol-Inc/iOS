//
//  DeleteGroupEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct DeleteGroupEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let groupId: String

    var method: HTTPMethod { .delete }
    var path: String { "/groups/\(groupId)" }
    var body: AnyEncodable? { nil }
}

