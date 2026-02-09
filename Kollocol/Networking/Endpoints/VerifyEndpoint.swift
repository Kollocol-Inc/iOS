//
//  VerifyEndpoint.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

struct VerifyEndpoint: Endpoint {
    typealias Response = VerifyCodeResponse

    let code: String
    let email: String

    var method: HTTPMethod { .post }
    var path: String { "/auth/verify" }
    var body: AnyEncodable? { AnyEncodable(Body(code: code, email: email)) }

    struct Body: Encodable, Sendable {
        let code: String
        let email: String
    }
}
