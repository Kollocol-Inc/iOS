//
//  DeleteQuizInstanceEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

struct DeleteQuizInstanceEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let instanceId: String

    var method: HTTPMethod { .delete }
    var path: String { "/quizzes/instances/\(instanceId)" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
