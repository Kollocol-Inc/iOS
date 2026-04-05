//
//  GenerateTemplateMLEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct GenerateTemplateMLEndpoint: Endpoint {
    typealias Response = GeneratedTemplateDTO

    let request: GenerateTemplateMLRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/ml/generate/template" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
