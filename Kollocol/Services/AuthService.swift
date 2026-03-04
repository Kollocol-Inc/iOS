//
//  AuthService.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import Foundation

// MARK: - AuthServiceImpl
actor AuthServiceImpl: AuthService {
    // MARK: - Properties
    private let api: APIClient
    private let tokenStore: any TokenStoring
    private let udService: UserDefaultsService

    // MARK: - Lifecycle
    init(api: APIClient, tokenStore: any TokenStoring, udService: UserDefaultsService) {
        self.api = api
        self.tokenStore = tokenStore
        self.udService = udService
    }
    
    // MARK: - Methods
    func login(using email: String) async throws {
        do {
            _ = try await api.request(LoginEndpoint(email: email))
        } catch {
            throw AuthServiceError.wrap(error)
        }
    }
    
    func logout() async throws {
        await tokenStore.clear()
        // await tokenStore.clear()
    }
    
    func refreshToken(with token: String) async throws {
        print(1)
    }
    
    func resendCode(to email: String) async throws {
        print(1)
    }
    
    func verify(code: String, with email: String) async throws -> Bool {
        do {
            let response = try await api.request(VerifyEndpoint(code: code, email: email))
            
            await tokenStore.set(
                TokenPair(
                    accessToken: response.accessToken,
                    refreshToken: response.refreshToken
                )
            )
            
            let isRegistered = response.isRegistered
            udService.isRegistered = isRegistered
            
            return isRegistered
        } catch {
            throw AuthServiceError.wrap(error)
        }
    }
}

// MARK: - AuthService
protocol AuthService: Actor {
    func login(using email: String) async throws
    func logout() async throws
    func refreshToken(with token: String) async throws
    func resendCode(to email: String) async throws
    func verify(code: String, with email: String) async throws -> Bool
}

// MARK: - AuthServiceError
enum AuthServiceError: Error, Sendable {
    case badRequest
    case tooManyRequests
    case unauthorized
    case offline
    case server
    case unknown
    
    static func mapStatusCode(_ code: Int) -> AuthServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 429 { return .tooManyRequests }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension AuthServiceError: NetworkServiceError {}
