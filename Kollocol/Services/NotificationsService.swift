//
//  NotificationsService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import Foundation

// MARK: - NotificationsServiceImpl
actor NotificationsServiceImpl: NotificationsService {
    // MARK: - Properties
    private let api: APIClient

    // MARK: - Lifecycle
    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Methods
    func getNotifications(_ request: GetUserNotificationsRequest) async throws -> UserNotificationsPage {
        do {
            let response = try await api.request(
                GetUserNotificationsEndpoint(
                    limit: request.limit,
                    offset: request.offset
                )
            )
            return response.toDomain()
        } catch {
            throw NotificationsServiceError.wrap(error)
        }
    }

    func deleteNotifications(_ request: NotificationIDsRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(DeleteNotificationsEndpoint(request: dto))
        } catch {
            throw NotificationsServiceError.wrap(error)
        }
    }

    func markNotificationsAsRead(_ request: NotificationIDsRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(ReadNotificationsEndpoint(request: dto))
        } catch {
            throw NotificationsServiceError.wrap(error)
        }
    }
}

// MARK: - NotificationsService
protocol NotificationsService: Actor {
    func getNotifications(_ request: GetUserNotificationsRequest) async throws -> UserNotificationsPage
    func deleteNotifications(_ request: NotificationIDsRequest) async throws
    func markNotificationsAsRead(_ request: NotificationIDsRequest) async throws
}

// MARK: - NotificationsServiceError
enum NotificationsServiceError: Error, Sendable {
    case badRequest
    case tooManyRequests
    case unauthorized
    case server
    case offline
    case unknown

    static func mapStatusCode(_ code: Int) -> NotificationsServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 429 { return .tooManyRequests }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension NotificationsServiceError: NetworkServiceError {}
