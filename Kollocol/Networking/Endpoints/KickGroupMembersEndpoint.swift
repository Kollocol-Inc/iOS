//
//  KickGroupMembersEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct KickGroupMembersEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let groupId: String
    let request: KickGroupMembersRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/groups/\(groupId)/kick" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
