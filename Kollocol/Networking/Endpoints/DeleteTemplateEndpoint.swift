//
//  DeleteTemplateEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 21.03.2026.
//

import Foundation

struct DeleteTemplateEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let templateId: String

    var method: HTTPMethod { .delete }
    var path: String { "/quizzes/templates/\(templateId)" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? { nil }
}
