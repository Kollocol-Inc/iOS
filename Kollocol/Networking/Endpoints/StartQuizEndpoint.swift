//
//  StartQuizEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

struct StartQuizEndpoint: Endpoint {
    typealias Response = CreateQuizInstanceResponse

    let request: CreateInstanceRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/instances" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
