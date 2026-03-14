//
//  QuizService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

// MARK: - UserServiceImpl
actor QuizServiceImpl: QuizService {
    // MARK: - Properties
    private let api: APIClient

    // MARK: - Lifecycle
    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Methods
    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        do {
            let response = try await api.request(GetParticipatingQuizInstancesEndpoint())
            let instances = response.instances.map { $0.toDomain() }
            return instances
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        do {
            let response = try await api.request(GetHostingQuizInstancesEndpoint())
            let instances = response.instances.map { $0.toDomain() }
            return instances
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getTemplates() async throws -> [QuizTemplate] {
        do {
            let response = try await api.request(GetTemplatesEndpoint())
            let templates = response.templates.map { $0.toDomain() }
            return templates
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(CreateTemplateEndpoint(request: dto))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }
}

// MARK: - UserServiceError
protocol QuizService: Actor {
    func getParticipatingQuizzes() async throws -> [ParticipatingInstance]
    func getHostingQuizzes() async throws -> [QuizInstance]
    func getTemplates() async throws -> [QuizTemplate]
    func createTemplate(_ request: CreateTemplateRequest) async throws
}

// MARK: - UserServiceError
enum QuizServiceError: Error, Sendable {
    case badRequest
    case unauthorized
    case tooManyRequests
    case server
    case offline
    case unknown

    static func mapStatusCode(_ code: Int) -> QuizServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 429 { return .tooManyRequests }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension QuizServiceError: NetworkServiceError {}
