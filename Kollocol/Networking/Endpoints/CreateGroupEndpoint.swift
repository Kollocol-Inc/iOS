//
//  CreateGroupEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct CreateGroupEndpoint: Endpoint {
    typealias Response = GroupDTO

    let request: CreateGroupRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/groups" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}

