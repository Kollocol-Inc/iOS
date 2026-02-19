//
//  UserService.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import Foundation

// MARK: - UserServiceImpl
actor UserServiceImpl: UserService {
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
    func getUserProfile() async throws -> UserDTO {
        do {
            return try await api.request(GetUserProfile())
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func updateUserProfile(name: String, surname: String) async throws -> UserDTO {
        do {
            return try await api.request(
                UpdateUserProfile(
                    name: name,
                    surname: surname
                )
            )
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func uploadAvatar(data: Data) async throws {
        do {
            let file = UploadAvatar.AvatarFile(data: data)
            _ = try await api.request(UploadAvatar(avatar: file))
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func getNotifications() async throws -> NotificationsSettingsDTO {
        do {
            return try await api.request(GetNotifications())
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func updateNotifications(
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    ) async throws -> NotificationsSettingsDTO {
        do {
            return try await api.request(
                UpdateNotifications(
                    deadlineReminder: deadlineReminder,
                    groupInvites: groupInvites,
                    newQuizzes: newQuizzes,
                    quizResults: quizResults
                )
            )
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func register(name: String, surname: String) async throws {
        do {
            _ = try await api.request(RegisterEndpoint(name: name, surname: surname))
            udService.isRegistered = true
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

    func deleteAvatar() async throws {
        // TODO: implement
    }

    // MARK: - Private Methods
    private func map(_ error: Error) -> UserServiceError {
        if let e = error as? UserServiceError { return e }

        guard let networkError = error as? NetworkError else {
            return .unknown
        }

        switch networkError {
        case .transport(let urlError):
            if urlError.code == .notConnectedToInternet { return .offline }
            return .unknown

        case .httpStatus(let code, _):
            if code == 400 { return .badRequest }
            if code == 401 { return .unauthorized }
            if (500...599).contains(code) { return .server }

            return .unknown

        default:
            return .unknown
        }
    }
}

// MARK: - UserServiceError
protocol UserService: Actor {
    func getUserProfile() async throws -> UserDTO
    func updateUserProfile(name: String, surname: String) async throws -> UserDTO
    func uploadAvatar(data: Data) async throws
    func getNotifications() async throws -> NotificationsSettingsDTO
    func updateNotifications(
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    ) async throws -> NotificationsSettingsDTO
    func register(name: String, surname: String) async throws
    func deleteAvatar() async throws
}

// MARK: - UserServiceError
enum UserServiceError: Error, Sendable {
    case badRequest
    case unauthorized
    case server
    case offline
    case unknown
    
    static func wrap(_ error: Error) -> UserServiceError {
        if let e = error as? UserServiceError { return e }
        return .unknown
    }
}
