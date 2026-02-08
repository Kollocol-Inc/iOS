//
//  RefreshClient.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

final class RefreshClient: TokenRefreshing {
    private let api: APIClient

    init(api: APIClient) {
        self.api = api
    }

    func refresh(using refreshToken: String) async throws -> TokenPair {
        let dto = try await api.request(RefreshEndpoint(refreshToken: refreshToken))
        return TokenPair(accessToken: dto.accessToken, refreshToken: dto.refreshToken)
    }
}
