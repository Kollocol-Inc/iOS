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

    // MARK: - Lifecycle
    init(api: APIClient) {
        self.api = api
    }
    
    // MARK: - Methods
    func login(using email: String) async throws {
        do {
            _ = try await api.request(LoginEndpoint(email: email))
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }
    
    func logout() async throws {
        print(1)
    }
    
    func refreshToken(with token: String) async throws {
        print(1)
    }
    
    func resendCode(to email: String) async throws {
        print(1)
    }
    
    func verify(code: String, with email: String) async throws {
        print(1)
    }
    
    // MARK: - Private Methods
    private func map(_ error: Error) -> AuthServiceError {
        if let e = error as? AuthServiceError { return e }

        guard let networkError = error as? NetworkError else {
            return .unknown
        }

        switch networkError {
        case .transport(let urlError):
            if urlError.code == .notConnectedToInternet { return .offline }
            return .unknown

        case .httpStatus(let code, _):
            if code == 400 { return .invalidEmail }
            if code == 429 { return .tooManyRequests }
            if code == 401 { return .unauthorized }
            if (500...599).contains(code) { return .server }

            return .unknown

        default:
            return .unknown
        }
    }
}

// MARK: - AuthService
protocol AuthService: Actor {
    func login(using email: String) async throws
    func logout() async throws
    func refreshToken(with token: String) async throws
    func resendCode(to email: String) async throws
    func verify(code: String, with email: String) async throws
}

// MARK: - AuthServiceError
enum AuthServiceError: Error, Sendable {
    case invalidEmail
    case tooManyRequests
    case invalidCode
    case unauthorized
    case offline
    case server
    case unknown
    
    static func wrap(_ error: Error) -> AuthServiceError {
        if let e = error as? AuthServiceError { return e }
        return .unknown
    }
}
