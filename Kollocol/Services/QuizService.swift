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
            let response = try await api.request(GetParticipatingQuizInstances())
            let instances = response.instances.map { $0.toDomain() }
            return instances
        } catch let networkError as NetworkError {
            throw map(networkError)
        } catch {
            throw map(error)
        }
    }

  func getHostingQuizzes() async throws -> [QuizInstance] {
    do {
      let response = try await api.request(GetHostingQuizInstances())
      let instances = response.instances.map { $0.toDomain() }
      return instances
    } catch let networkError as NetworkError {
      throw map(networkError)
    } catch {
      throw map(error)
    }
  }

    // MARK: - Private Methods
    private func map(_ error: Error) -> QuizServiceError {
        if let e = error as? QuizServiceError { return e }

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
protocol QuizService: Actor {
    func getParticipatingQuizzes() async throws -> [ParticipatingInstance]
    func getHostingQuizzes() async throws -> [QuizInstance]
}

// MARK: - UserServiceError
enum QuizServiceError: Error, Sendable {
    case badRequest
    case unauthorized
    case server
    case offline
    case unknown

    static func wrap(_ error: Error) -> QuizServiceError {
        if let e = error as? QuizServiceError { return e }
        return .unknown
    }
}
