//
//  GradeQuizAnswerEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GradeQuizAnswerEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let instanceId: String
    let request: GradeAnswerRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/instances/\(instanceId)/grade" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
