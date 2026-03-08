//
//  GetParticipatingQuizInstances.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct GetParticipatingQuizInstancesEndpoint: Endpoint {
    typealias Response = GetParticipatingInstancesResponse

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/participating" }
    var body: AnyEncodable? { nil }
}
