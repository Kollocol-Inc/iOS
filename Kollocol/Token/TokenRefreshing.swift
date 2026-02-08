//
//  TokenRefreshing.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

protocol TokenRefreshing: Sendable {
    func refresh(using refreshToken: String) async throws -> TokenPair
}
