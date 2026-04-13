//
//  GetQuizInstanceEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetQuizInstanceEndpoint: Endpoint {
    typealias Response = GetInstanceResponse

    let instanceId: String

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/\(instanceId)" }
    var body: AnyEncodable? { nil }
}
