//
//  Endpoint.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

protocol Endpoint {
    associatedtype Response: Decodable

    var method: HTTPMethod { get }
    var path: String { get }
    var query: [URLQueryItem] { get }
    var headers: [String: String] { get }
    var body: AnyEncodable? { get }
}

extension Endpoint {
    var query: [URLQueryItem] { [] }
    var headers: [String: String] { [:] }
    var body: AnyEncodable? { nil }
}
