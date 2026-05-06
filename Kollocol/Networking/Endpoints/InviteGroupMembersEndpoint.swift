//
//  InviteGroupMembersEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct InviteGroupMembersEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let groupId: String
    let request: InviteGroupMembersRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/groups/\(groupId)/invite" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
