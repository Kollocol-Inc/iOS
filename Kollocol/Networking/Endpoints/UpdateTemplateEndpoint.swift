//
//  UpdateTemplateEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 21.03.2026.
//

import Foundation

struct UpdateTemplateEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let templateId: String
    let request: CreateTemplateRequestDTO

    var method: HTTPMethod { .put }
    var path: String { "/quizzes/templates/\(templateId)" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
