//
//  RefreshEndpoint.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

struct RefreshEndpoint: Endpoint {
    typealias Response = RefreshResponse

    let refreshToken: String

    var method: HTTPMethod { .post }
    var path: String { "/auth/refresh" }
    var body: AnyEncodable? { AnyEncodable(Body(refreshToken: refreshToken)) }

    struct Body: Encodable, Sendable {
        let refreshToken: String
        
        private enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }
}
