//
//  GetTemplateByIdEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 21.03.2026.
//

import Foundation

struct GetTemplateByIdEndpoint: Endpoint {
    typealias Response = GetTemplateByIdResponse

    let templateId: String

    var method: HTTPMethod { .get }
    var path: String { "/quizzes/templates/\(templateId)" }
    var body: AnyEncodable? { nil }
}
