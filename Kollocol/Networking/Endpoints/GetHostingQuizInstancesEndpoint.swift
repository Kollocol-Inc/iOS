//
//  GetHostingQuizInstances.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 03.03.2026.
//

import Foundation

struct GetHostingQuizInstancesEndpoint: Endpoint {
    typealias Response = GetHostingInstancesResponse

    let status: QuizStatus?

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/hosting" }
    var query: [URLQueryItem] {
        guard let status else { return [] }
        return [URLQueryItem(name: "status", value: status.rawValue)]
    }
    var body: AnyEncodable? { nil }
}
