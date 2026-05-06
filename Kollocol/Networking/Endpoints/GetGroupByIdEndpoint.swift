//
//  GetGroupByIdEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GetGroupByIdEndpoint: Endpoint {
    typealias Response = GroupWithMembersDTO

    let groupId: String

    var method: HTTPMethod { .get }
    var path: String { "/groups/\(groupId)" }
    var body: AnyEncodable? { nil }
}

