//
//  QuizParticipationServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizParticipationServiceImplTests {
    @Test
    func initialStateIsDisconnectedWithEmptyCaches() async {
        let service = makeQuizParticipationService(accessToken: nil)

        #expect(await service.currentConnectionState() == .disconnected)
        #expect(await service.currentConnectedPayload() == nil)
        #expect(await service.currentQuizTitle() == nil)
        #expect(await service.currentParticipantsCount() == 1)
        #expect(await service.currentParticipants().isEmpty)
        #expect(await service.currentQuestionPayload() == nil)
        #expect(await service.currentLeaderboardPayload() == nil)
    }

    @Test
    func makeEventStreamImmediatelyYieldsCurrentConnectionState() async throws {
        let service = makeQuizParticipationService(accessToken: nil)
        let stream = await service.makeEventStream()
        var iterator = stream.makeAsyncIterator()

        let firstEvent = try #require(await iterator.next())
        #expect(firstEvent == .connectionChanged(.disconnected))
    }

    @Test
    func sendCommandWithoutConnectionThrowsNotConnected() async {
        let service = makeQuizParticipationService(accessToken: nil)

        do {
            try await service.sendCommand(type: "custom")
            Issue.record("Expected QuizParticipationServiceError.notConnected")
        } catch let error as QuizParticipationServiceError {
            #expect(error == .notConnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func startQuizWithoutConnectionThrowsNotConnected() async {
        let service = makeQuizParticipationService(accessToken: nil)

        do {
            try await service.startQuiz()
            Issue.record("Expected QuizParticipationServiceError.notConnected")
        } catch let error as QuizParticipationServiceError {
            #expect(error == .notConnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func sendAnswerWithoutConnectionThrowsNotConnected() async {
        let service = makeQuizParticipationService(accessToken: nil)

        do {
            try await service.sendAnswer(questionId: "q-1", answer: "A", timeSpentMs: 1_200)
            Issue.record("Expected QuizParticipationServiceError.notConnected")
        } catch let error as QuizParticipationServiceError {
            #expect(error == .notConnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func kickParticipantWithoutConnectionThrowsNotConnected() async {
        let service = makeQuizParticipationService(accessToken: nil)

        do {
            try await service.kickParticipant(email: "student@example.com")
            Issue.record("Expected QuizParticipationServiceError.notConnected")
        } catch let error as QuizParticipationServiceError {
            #expect(error == .notConnected)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func connectWithoutAccessTokenThrowsUnauthorizedAndReturnsToDisconnectedState() async throws {
        let service = makeQuizParticipationService(accessToken: nil)
        let stream = await service.makeEventStream()
        var iterator = stream.makeAsyncIterator()

        let initialEvent = try #require(await iterator.next())
        #expect(initialEvent == .connectionChanged(.disconnected))

        do {
            try await service.connect(accessCode: "ABCD")
            Issue.record("Expected QuizParticipationServiceError.unauthorized")
        } catch let error as QuizParticipationServiceError {
            #expect(error == .unauthorized)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let connectingEvent = try #require(await iterator.next())
        #expect(connectingEvent == .connectionChanged(.connecting(accessCode: "ABCD")))

        let disconnectedEvent = try #require(await iterator.next())
        #expect(disconnectedEvent == .connectionChanged(.disconnected))

        #expect(await service.currentConnectionState() == .disconnected)
        #expect(await service.currentConnectedPayload() == nil)
        #expect(await service.currentParticipantsCount() == 1)
        #expect(await service.currentParticipants().isEmpty)
        #expect(await service.currentQuestionPayload() == nil)
        #expect(await service.currentLeaderboardPayload() == nil)
    }

    @Test
    func serviceErrorWrapMapsUrlErrorCodes() {
        #expect(QuizParticipationServiceError.wrap(URLError(.notConnectedToInternet)) == .offline)
        #expect(QuizParticipationServiceError.wrap(URLError(.userAuthenticationRequired)) == .unauthorized)
        #expect(QuizParticipationServiceError.wrap(URLError(.networkConnectionLost)) == .connectionClosed)
        #expect(QuizParticipationServiceError.wrap(URLError(.badServerResponse)) == .invalidCode)
        #expect(QuizParticipationServiceError.wrap(URLError(.timedOut)) == .connectionTimeout)
        #expect(QuizParticipationServiceError.wrap(URLError(.cannotFindHost)) == .unknown)
    }
}

private actor QuizParticipationTokenStoreMock: TokenStoring {
    private var accessTokenStorage: String?
    private var refreshTokenStorage: String?

    init(accessToken: String?, refreshToken: String? = nil) {
        accessTokenStorage = accessToken
        refreshTokenStorage = refreshToken
    }

    func accessToken() async -> String? {
        accessTokenStorage
    }

    func refreshToken() async -> String? {
        refreshTokenStorage
    }

    func set(_ pair: TokenPair) async {
        accessTokenStorage = pair.accessToken
        refreshTokenStorage = pair.refreshToken
    }

    func clear() async {
        accessTokenStorage = nil
        refreshTokenStorage = nil
    }
}

private struct QuizParticipationRefresherMock: TokenRefreshing {
    func refresh(using refreshToken: String) async throws -> TokenPair {
        TokenPair(accessToken: "refreshed-access", refreshToken: "refreshed-refresh")
    }
}

private func makeQuizParticipationService(accessToken: String?) -> QuizParticipationServiceImpl {
    let store = QuizParticipationTokenStoreMock(accessToken: accessToken)
    let sessionManager = SessionManager(
        store: store,
        refresher: QuizParticipationRefresherMock(),
        onForcedLogout: {}
    )

    return QuizParticipationServiceImpl(
        baseURL: URL(string: "https://example.com")!,
        sessionManager: sessionManager,
        logger: { _ in }
    )
}
