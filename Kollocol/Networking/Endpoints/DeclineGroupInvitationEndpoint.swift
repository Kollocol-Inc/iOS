//
//  DeclineGroupInvitationEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct DeclineGroupInvitationEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let groupId: String

    var method: HTTPMethod { .post }
    var path: String { "/groups/\(groupId)/decline" }
    var body: AnyEncodable? { nil }
}
