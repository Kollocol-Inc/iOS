//
//  ParaphraseMLEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct ParaphraseMLEndpoint: Endpoint {
    typealias Response = ParaphraseMLResponse

    let request: ParaphraseMLRequestDTO

    var method: HTTPMethod { .post }
    var path: String { "/ml/paraphrase" }
    var body: AnyEncodable? { AnyEncodable(request) }
    var multipart: MultipartFormData? { nil }
}
