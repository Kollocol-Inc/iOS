//
//  AcceptGroupInvitationEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct AcceptGroupInvitationEndpoint: Endpoint {
    typealias Response = GroupDTO

    let groupId: String

    var method: HTTPMethod { .post }
    var path: String { "/groups/\(groupId)/accept" }
    var body: AnyEncodable? { nil }
}
