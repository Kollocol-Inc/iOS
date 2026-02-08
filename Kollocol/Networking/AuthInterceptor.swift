//
//  AuthInterceptor.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

final class AuthInterceptor: RequestInterceptor {
    private let session: SessionManager
    private let refreshPath: String

    init(session: SessionManager, refreshPath: String) {
        self.session = session
        self.refreshPath = refreshPath
    }

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let url = request.url, url.path != refreshPath else { return request }

        var req = request
        if let token = await session.accessToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    func shouldRetry(
        request: URLRequest,
        response: HTTPURLResponse,
        data: Data,
        attempt: Int
    ) async -> Bool {
        guard attempt == 0 else { return false }
        guard response.statusCode == 401 || response.statusCode == 403 else { return false }

        do {
            _ = try await session.refreshTokens()
            return true
        } catch {
            await session.forcedLogout()
            return false
        }
    }

    func forcedLogout() async {
        await session.forcedLogout()
    }
}
