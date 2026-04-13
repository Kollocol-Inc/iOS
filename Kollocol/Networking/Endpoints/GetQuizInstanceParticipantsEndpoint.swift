//
//  GetQuizInstanceParticipantsEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetQuizInstanceParticipantsEndpoint: Endpoint {
    typealias Response = GetInstanceParticipantsResponse

    let instanceId: String

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/\(instanceId)/participants" }
    var body: AnyEncodable? { nil }
}
