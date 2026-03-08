//
//  GetHostingQuizInstances.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 03.03.2026.
//

import Foundation

struct GetHostingQuizInstancesEndpoint: Endpoint {
    typealias Response = GetHostingInstancesResponse

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/instances/hosting" }
    var body: AnyEncodable? { nil }
}
