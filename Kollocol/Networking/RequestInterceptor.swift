//
//  RequestInterceptor.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

protocol RequestInterceptor: AnyObject {
    func adapt(_ request: URLRequest) async throws -> URLRequest
    func shouldRetry(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        attempt: Int
    ) async -> Bool
    func forcedLogout() async
}
