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
        } catch {
            throw UserServiceError.wrap(error)
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
        } catch {
            throw UserServiceError.wrap(error)
        }
    }

    func uploadAvatar(data: Data) async throws {
        do {
            let file = UploadAvatar.AvatarFile(data: data)
            _ = try await api.request(UploadAvatar(avatar: file))
        } catch {
            throw UserServiceError.wrap(error)
        }
    }

    func getNotifications() async throws -> NotificationsSettingsDTO {
        do {
            return try await api.request(GetNotifications())
        } catch {
            throw UserServiceError.wrap(error)
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
        } catch {
            throw UserServiceError.wrap(error)
        }
    }

    func register(name: String, surname: String) async throws {
        do {
            _ = try await api.request(RegisterEndpoint(name: name, surname: surname))
            udService.isRegistered = true
        } catch {
            throw UserServiceError.wrap(error)
        }
    }

    func deleteAvatar() async throws {
        // TODO: implement
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
    case tooManyRequests
    case unauthorized
    case server
    case offline
    case unknown
    
    static func mapStatusCode(_ code: Int) -> UserServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 429 { return .tooManyRequests }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension UserServiceError: NetworkServiceError {}
