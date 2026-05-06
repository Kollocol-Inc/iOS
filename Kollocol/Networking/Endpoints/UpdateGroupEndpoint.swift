//
//  UpdateGroupEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct UpdateGroupEndpoint: Endpoint {
    typealias Response = GroupDTO

    let groupId: String
    let request: UpdateGroupRequestDTO

    var method: HTTPMethod { .put }
    var path: String { "/groups/\(groupId)" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}

