//
//  GetUserProfile.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import Foundation

struct GetUserProfileEndpoint: Endpoint {
    typealias Response = UserDTO

    var method: HTTPMethod { .get }
    var path: String { "/users/me" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
