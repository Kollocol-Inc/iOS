//
//  CreateTemplateEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 10.03.2026.
//

import Foundation

struct CreateTemplateEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let description: String? = nil
    let questions

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/templates" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
