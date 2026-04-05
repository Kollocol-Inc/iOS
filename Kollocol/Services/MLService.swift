//
//  MLService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

// MARK: - MLServiceImpl
actor MLServiceImpl: MLService {
    // MARK: - Properties
    private let api: APIClient

    // MARK: - Lifecycle
    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Methods
    func generateTemplate(_ request: GenerateTemplateMLRequest) async throws -> GeneratedTemplate {
        do {
            let dto = request.toDto()
            let response = try await api.request(GenerateTemplateMLEndpoint(request: dto))
            return response.toDomain()
        } catch {
            throw MLServiceError.wrap(error)
        }
    }

    func generateTemplateQuestions(_ request: GenerateTemplateQuestionsMLRequest) async throws -> GeneratedQuestions {
        do {
            let dto = request.toDto()
            let response = try await api.request(GenerateTemplateQuestionsMLEndpoint(request: dto))
            return response.toDomain()
        } catch {
            throw MLServiceError.wrap(error)
        }
    }

    func paraphrase(_ request: ParaphraseMLRequest) async throws -> ParaphrasedText {
        do {
            let dto = request.toDto()
            let response = try await api.request(ParaphraseMLEndpoint(request: dto))
            return response.toDomain()
        } catch {
            throw MLServiceError.wrap(error)
        }
    }
}

// MARK: - MLService
protocol MLService: Actor {
    func generateTemplate(_ request: GenerateTemplateMLRequest) async throws -> GeneratedTemplate
    func generateTemplateQuestions(_ request: GenerateTemplateQuestionsMLRequest) async throws -> GeneratedQuestions
    func paraphrase(_ request: ParaphraseMLRequest) async throws -> ParaphrasedText
}

// MARK: - MLServiceError
enum MLServiceError: Error, Sendable {
    case badRequest
    case unauthorized
    case tooManyRequests
    case server
    case offline
    case unknown

    static func mapStatusCode(_ code: Int) -> MLServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 429 { return .tooManyRequests }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension MLServiceError: NetworkServiceError {}
