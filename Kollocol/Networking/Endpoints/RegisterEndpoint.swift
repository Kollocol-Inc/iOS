//
//  RegisterEndpoint.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

struct RegisterEndpoint: Endpoint {
    typealias Response = RegisterResponse

    let name: String
    let surname: String

    var method: HTTPMethod { .post }
    var path: String { "/users/register" }
    var body: AnyEncodable? { AnyEncodable(Body(name: name, surname: surname)) }

    struct Body: Encodable, Sendable {
        let name: String
        let surname: String
        
        private enum CodingKeys: String, CodingKey {
            case name = "first_name"
            case surname = "last_name"
        }
    }
}
