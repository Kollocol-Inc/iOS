//
//  PublishQuizResultsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct PublishQuizResultsEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let instanceId: String

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/instances/\(instanceId)/publish" }
    var body: AnyEncodable? { nil }
}
