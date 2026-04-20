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
        return try await getParticipatingQuizzes(sessionStatus: nil)
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        do {
            let response = try await api.request(
                GetParticipatingQuizInstancesEndpoint(sessionStatus: sessionStatus)
            )
            let instances = response.instances.map { $0.toDomain() }
            return instances
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        return try await getHostingQuizzes(status: nil)
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        do {
            let response = try await api.request(
                GetHostingQuizInstancesEndpoint(status: status)
            )
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

    func getTemplate(by templateId: String) async throws -> QuizTemplate {
        do {
            let response = try await api.request(GetTemplateByIdEndpoint(templateId: templateId))
            let template = response.template.toDomain()
            return template
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

    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(UpdateTemplateEndpoint(templateId: templateId, request: dto))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func deleteTemplate(by templateId: String) async throws {
        do {
            _ = try await api.request(DeleteTemplateEndpoint(templateId: templateId))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    @discardableResult
    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String? {
        do {
            let dto = request.toDto()
            let response = try await api.request(StartQuizEndpoint(request: dto))
            let accessCode = response.accessCode?.trimmingCharacters(in: .whitespacesAndNewlines)
            return accessCode?.isEmpty == false ? accessCode : nil
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        do {
            let response = try await api.request(GetQuizInstanceEndpoint(instanceId: instanceId))
            return QuizInstanceDetails(
                instance: response.instance?.toDomain(),
                questions: response.questions?.map { $0.toDomain() } ?? []
            )
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func deleteQuizInstance(by instanceId: String) async throws {
        do {
            _ = try await api.request(DeleteQuizInstanceEndpoint(instanceId: instanceId))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        do {
            let response = try await api.request(GetQuizInstanceParticipantsEndpoint(instanceId: instanceId))
            return response.participants.map { $0.toDomain() }
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func getParticipantAnswers(instanceId: String, participantId: String) async throws -> QuizParticipantAnswersDetails {
        do {
            let response = try await api.request(
                GetQuizParticipantAnswersEndpoint(
                    instanceId: instanceId,
                    participantId: participantId
                )
            )
            return QuizParticipantAnswersDetails(
                answers: response.answers?.map { $0.toDomain() } ?? [],
                instance: response.instance?.toDomain(),
                questions: response.questions?.map { $0.toDomain() } ?? []
            )
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(GradeQuizAnswerEndpoint(instanceId: instanceId, request: dto))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func reviewParticipantAnswer(
        instanceId: String,
        request: ReviewAnswerRequest
    ) async throws -> QuizAnswerReviewSuggestion {
        do {
            let dto = request.toDto()
            let response = try await api.request(
                ReviewQuizAnswerEndpoint(
                    instanceId: instanceId,
                    request: dto
                )
            )
            return response.toDomain()
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }

    func publishQuizResults(instanceId: String) async throws {
        do {
            _ = try await api.request(PublishQuizResultsEndpoint(instanceId: instanceId))
        } catch {
            throw QuizServiceError.wrap(error)
        }
    }
}

// MARK: - UserServiceError
protocol QuizService: Actor {
    func getParticipatingQuizzes() async throws -> [ParticipatingInstance]
    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance]
    func getHostingQuizzes() async throws -> [QuizInstance]
    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance]
    func getTemplates() async throws -> [QuizTemplate]
    func getTemplate(by templateId: String) async throws -> QuizTemplate
    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws
    func createTemplate(_ request: CreateTemplateRequest) async throws
    func deleteTemplate(by templateId: String) async throws
    @discardableResult
    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String?
    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails
    func deleteQuizInstance(by instanceId: String) async throws
    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant]
    func getParticipantAnswers(instanceId: String, participantId: String) async throws -> QuizParticipantAnswersDetails
    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws
    func reviewParticipantAnswer(instanceId: String, request: ReviewAnswerRequest) async throws -> QuizAnswerReviewSuggestion
    func publishQuizResults(instanceId: String) async throws
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
