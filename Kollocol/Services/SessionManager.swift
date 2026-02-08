//
//  SessionManager.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

actor SessionManager {
    private let store: any TokenStoring
    private let refresher: TokenRefreshing
    private let onForcedLogout: @MainActor @Sendable () -> Void

    private var refreshTask: Task<TokenPair, Error>?

    init(
        store: any TokenStoring,
        refresher: TokenRefreshing,
        onForcedLogout: @MainActor @Sendable @escaping () -> Void
    ) {
        self.store = store
        self.refresher = refresher
        self.onForcedLogout = onForcedLogout
    }

    func accessToken() async -> String? {
        await store.accessToken()
    }

    func refreshTokens() async throws -> TokenPair {
        if let task = refreshTask {
            return try await task.value
        }

        let task = Task<TokenPair, Error> {
            guard let refresh = await store.refreshToken() else {
                throw AuthServiceError.unauthorized
            }
            let pair = try await refresher.refresh(using: refresh)
            await store.set(pair)
            return pair
        }

        refreshTask = task

        do {
            let pair = try await task.value
            refreshTask = nil
            return pair
        } catch {
            refreshTask = nil
            throw error
        }
    }

    func forcedLogout() async {
        await store.clear()
        await MainActor.run {
            onForcedLogout()
        }
    }
}
