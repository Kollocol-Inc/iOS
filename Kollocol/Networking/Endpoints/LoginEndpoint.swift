//
//  LoginEndpoint.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

struct LoginEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let email: String

    var method: HTTPMethod { .post }
    var path: String { "/auth/login" }
    var body: AnyEncodable? { AnyEncodable(Body(email: email)) }

    struct Body: Encodable, Sendable {
        let email: String
    }
}
