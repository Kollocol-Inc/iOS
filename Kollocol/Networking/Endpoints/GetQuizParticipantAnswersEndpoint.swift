//
//  GetQuizParticipantAnswersEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetQuizParticipantAnswersEndpoint: Endpoint {
    typealias Response = GetParticipantAnswersResponse

    let instanceId: String
    let participantId: String

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/\(instanceId)/participants/\(participantId)/answers" }
    var body: AnyEncodable? { nil }
}
