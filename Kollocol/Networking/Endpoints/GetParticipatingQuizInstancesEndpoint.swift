//
//  GetParticipatingQuizInstances.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct GetParticipatingQuizInstancesEndpoint: Endpoint {
    typealias Response = GetParticipatingInstancesResponse

    let sessionStatus: SessionStatus?

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/participating" }
    var query: [URLQueryItem] {
        guard let sessionStatus else { return [] }
        return [URLQueryItem(name: "session_status", value: sessionStatus.rawValue)]
    }
    var body: AnyEncodable? { nil }
}
