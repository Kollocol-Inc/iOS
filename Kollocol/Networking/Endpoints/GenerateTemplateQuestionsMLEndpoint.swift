//
//  GenerateTemplateQuestionsMLEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateQuestionsMLEndpoint: Endpoint {
    typealias Response = GenerateTemplateQuestionsResponse

    let request: GenerateTemplateQuestionsMLRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/ml/generate/template/questions" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
