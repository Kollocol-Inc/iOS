//
//  GetGroupsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GetGroupsEndpoint: Endpoint {
    typealias Response = GetGroupsResponse

    let filter: GroupFilter?

    var method: HTTPMethod { .get }
    var path: String { "/groups" }
    var query: [URLQueryItem] {
        guard let filter else { return [] }
        return [URLQueryItem(name: "filter", value: filter.rawValue)]
    }
    var body: AnyEncodable? { nil }
}

