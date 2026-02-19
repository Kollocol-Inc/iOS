//
//  UpdateUserProfile.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import Foundation

struct UpdateUserProfile: Endpoint {
    typealias Response = UserDTO

    let name: String
    let surname: String

    var method: HTTPMethod { .put }
    var path: String { "/users/me" }
    var body: AnyEncodable? { AnyEncodable(Body(name: name, surname: surname)) }
    var multipart: MultipartFormData? { nil }

    struct Body: Encodable, Sendable {
        let name: String
        let surname: String

        private enum CodingKeys: String, CodingKey {
            case name = "first_name"
            case surname = "last_name"
        }
    }
}
