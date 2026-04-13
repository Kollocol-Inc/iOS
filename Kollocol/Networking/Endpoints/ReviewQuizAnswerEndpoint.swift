//
//  ReviewQuizAnswerEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct ReviewQuizAnswerEndpoint: Endpoint {
    typealias Response = ReviewAnswerResponse

    let instanceId: String
    let request: ReviewAnswerRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/instances/\(instanceId)/review" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
