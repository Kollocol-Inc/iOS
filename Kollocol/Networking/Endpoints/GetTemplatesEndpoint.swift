//
//  GetTemplatesEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct GetTemplatesEndpoint: Endpoint {
    typealias Response = GetTemplatesResponse

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/templates" }
    var body: AnyEncodable? { nil }
}
