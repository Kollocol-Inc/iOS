//
//  QuizParticipationService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

struct QuizParticipationWebSocketConfiguration: Sendable {
    let path: String
    let tokenQueryName: String
    let accessCodeQueryName: String

    static let `default` = QuizParticipationWebSocketConfiguration(
        path: "/ws",
        tokenQueryName: "token",
        accessCodeQueryName: "access_code"
    )
}

protocol QuizParticipationService: Actor {
    func connect(accessCode: String) async throws
    func disconnect() async
    func currentConnectionState() -> QuizParticipationConnectionState
    func currentConnectedPayload() -> QuizConnectedPayload?
    func currentQuizTitle() -> String?
    func currentParticipantsCount() -> Int
    func currentParticipants() -> [QuizParticipant]
    func currentQuestionPayload() -> QuizQuestionPayload?
    func currentLeaderboardPayload() -> QuizLeaderboardPayload?
    func makeEventStream() -> AsyncStream<QuizParticipationEvent>
    func startQuiz() async throws
    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws
    func sendCommand(type: String) async throws
    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws
}

// MARK: - QuizParticipationServiceImpl
actor QuizParticipationServiceImpl: QuizParticipationService {
    // MARK: - Constants
    private enum Constants {
        static let pingIntervalNanoseconds: UInt64 = 20_000_000_000
        static let connectionTimeoutNanoseconds: UInt64 = 10_000_000_000
        static let connectionPollNanoseconds: UInt64 = 100_000_000
        static let maxLogMessageLength = 8_000
    }

    // MARK: - Properties
    private let baseURL: URL
    private let session: URLSession
    private let sessionManager: SessionManager
    private let configuration: QuizParticipationWebSocketConfiguration
    private let logger: @Sendable (String) -> Void
    private static let logDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let encoder = JSONEncoder()

    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var subscribers: [UUID: AsyncStream<QuizParticipationEvent>.Continuation] = [:]
    private var connectionState: QuizParticipationConnectionState = .disconnected
    private var lastConnectedPayload: QuizConnectedPayload?
    private var quizTitle: String?
    private var pendingConnectionError: QuizParticipationServiceError?
    private var participantsCount = 1
    private var participants: [QuizParticipant] = []
    private var latestQuestionPayload: QuizQuestionPayload?
    private var latestLeaderboardPayload: QuizLeaderboardPayload?

    // MARK: - Lifecycle
    init(
        baseURL: URL,
        sessionManager: SessionManager,
        session: URLSession = .shared,
        configuration: QuizParticipationWebSocketConfiguration = .default,
        logger: @escaping @Sendable (String) -> Void = { Swift.print($0) }
    ) {
        self.baseURL = baseURL
        self.sessionManager = sessionManager
        self.session = session
        self.configuration = configuration
        self.logger = logger
    }

    // MARK: - Methods
    func connect(accessCode: String) async throws {
        logInfo("connect requested. accessCode=\(accessCode), currentState=\(connectionStateDescription(connectionState))")
        if case .connected(let currentAccessCode) = connectionState, currentAccessCode == accessCode {
            logInfo("connect skipped: already connected with the same access code.")
            return
        }

        await disconnect()
        logDebug("state reset before new websocket connection")
        lastConnectedPayload = nil
        quizTitle = nil
        pendingConnectionError = nil
        participantsCount = 1
        participants = []
        latestQuestionPayload = nil
        latestLeaderboardPayload = nil
        updateConnectionState(.connecting(accessCode: accessCode))

        do {
            let request = try await makeRequest(accessCode: accessCode)
            logInfo("opening websocket: \(maskedURLDescription(request.url))")
            let webSocketTask = session.webSocketTask(with: request)
            self.webSocketTask = webSocketTask
            webSocketTask.resume()
            logInfo("websocket task resumed")

            startReceiveLoop()
            startPingLoop()

            let connectedPayload = try await waitForConnectedPayload()
            logInfo("connected payload received: sessionId=\(connectedPayload.sessionId ?? "nil"), isCreator=\(connectedPayload.isCreator), status=\(connectedPayload.quizStatus?.rawValue ?? "nil")")
            updateConnectionState(.connected(accessCode: accessCode))
        } catch {
            logError("connect failed: \(error)")
            await disconnect()
            throw QuizParticipationServiceError.wrap(error)
        }
    }

    func disconnect() async {
        logInfo("disconnect requested")
        receiveTask?.cancel()
        receiveTask = nil

        pingTask?.cancel()
        pingTask = nil

        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        lastConnectedPayload = nil
        quizTitle = nil
        pendingConnectionError = nil
        participantsCount = 1
        participants = []
        latestQuestionPayload = nil
        latestLeaderboardPayload = nil
        updateConnectionState(.disconnected)
        logInfo("disconnect completed; local websocket cache cleared")
    }

    func currentConnectionState() -> QuizParticipationConnectionState {
        connectionState
    }

    func currentConnectedPayload() -> QuizConnectedPayload? {
        lastConnectedPayload
    }

    func currentQuizTitle() -> String? {
        quizTitle
    }

    func currentParticipantsCount() -> Int {
        max(1, max(participantsCount, participants.count))
    }

    func currentParticipants() -> [QuizParticipant] {
        participants
    }

    func currentQuestionPayload() -> QuizQuestionPayload? {
        latestQuestionPayload
    }

    func currentLeaderboardPayload() -> QuizLeaderboardPayload? {
        latestLeaderboardPayload
    }

    func makeEventStream() -> AsyncStream<QuizParticipationEvent> {
        AsyncStream { continuation in
            let id = UUID()
            subscribers[id] = continuation
            logDebug("subscriber added: id=\(id.uuidString), total=\(subscribers.count)")

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeSubscriber(id)
                }
            }

            continuation.yield(.connectionChanged(connectionState))
        }
    }

    func startQuiz() async throws {
        try await sendCommand(type: "start_quiz")
    }

    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws {
        let payload = AnswerPayload(
            questionId: questionId,
            answer: answer,
            timeSpentMs: timeSpentMs
        )
        try await sendCommand(type: "answer", payload: payload)
    }

    func sendCommand(type: String) async throws {
        try await sendCommand(type: type, payload: EmptyPayload())
    }

    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws {
        guard let webSocketTask else {
            logError("sendCommand failed: websocket is not connected. type=\(type)")
            throw QuizParticipationServiceError.notConnected
        }

        let message = OutgoingMessage(type: type, payload: payload)
        let messageData: Data

        do {
            messageData = try encoder.encode(message)
        } catch {
            throw QuizParticipationServiceError.encodingFailed
        }

        guard let messageText = String(data: messageData, encoding: .utf8) else {
            throw QuizParticipationServiceError.encodingFailed
        }

        logOut(type: type, payloadSummary: truncated(messageText))
        do {
            try await webSocketTask.send(.string(messageText))
            logDebug("sendCommand succeeded. type=\(type)")
        } catch {
            logError("sendCommand failed. type=\(type), error=\(error)")
            throw QuizParticipationServiceError.wrap(error)
        }
    }

    // MARK: - Private Methods
    private func startReceiveLoop() {
        receiveTask?.cancel()
        logDebug("starting receive loop")
        receiveTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveLoop()
        }
    }

    private func startPingLoop() {
        pingTask?.cancel()
        logDebug("starting ping loop")
        pingTask = Task { [weak self] in
            guard let self else { return }

            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: Constants.pingIntervalNanoseconds)
                if Task.isCancelled {
                    return
                }
                await self.sendPingIfConnected()
            }
        }
    }

    private func receiveLoop() async {
        logDebug("receive loop entered")
        while Task.isCancelled == false {
            guard let webSocketTask else {
                logDebug("receive loop finished: websocket task missing")
                return
            }

            do {
                let message = try await webSocketTask.receive()
                await handleReceivedMessage(message)
            } catch {
                if Task.isCancelled {
                    logDebug("receive loop cancelled")
                    return
                }

                logError("receive loop failed: \(error)")
                await handleSocketFailure(QuizParticipationServiceError.wrap(error))
                return
            }
        }
    }

    private func handleReceivedMessage(_ message: URLSessionWebSocketTask.Message) async {
        let parsedMessages: [QuizParticipationMessage]

        switch message {
        case .string(let text):
            logInRaw(text)
            parsedMessages = parseIncomingMessages(text)

        case .data(let data):
            let text = String(data: data, encoding: .utf8) ?? "bytes=\(data.count)"
            logInRaw(text)
            parsedMessages = parseIncomingMessages(text)

        @unknown default:
            parsedMessages = [
                .unknown(
                    type: "unknown",
                    payloadSummary: nil,
                    rawText: "unknown message"
                )
            ]
        }

        parsedMessages.forEach { parsedMessage in
            logInParsed(parsedMessage)
            if case .connected(let payload) = parsedMessage {
                lastConnectedPayload = payload
                logDebug("cached connected payload: sessionId=\(payload.sessionId ?? "nil"), isCreator=\(payload.isCreator)")
            }

            if case .participantsUpdate(let payload) = parsedMessage {
                applyParticipantsUpdateToCache(payload)
            }

            if case .participantsList(let payload) = parsedMessage {
                participants = payload.participants
                participantsCount = max(1, payload.participants.count)
                quizTitle = payload.quizTitle
                logDebug("participants list cached: participants=\(participants.count), participantsCount=\(participantsCount), title=\(quizTitle ?? "nil")")
            }

            if case .question(let payload) = parsedMessage {
                latestQuestionPayload = payload
                logDebug("question cached: index=\(payload.questionIndex), id=\(payload.question.id ?? "nil"), type=\(payload.question.type?.rawValue ?? "nil")")
            }

            if case .leaderboard(let payload) = parsedMessage {
                latestLeaderboardPayload = payload
                logDebug("leaderboard cached: entries=\(payload.leaderboard.count), canContinue=\(payload.canContinue), optionStats=\(payload.answerOptionStats.count)")
            }

            if case .answerProgress(let payload) = parsedMessage {
                participantsCount = max(1, max(participantsCount, payload.totalParticipants))
                logDebug("answer progress cached: answered=\(payload.participantsAnswered), total=\(payload.totalParticipants), participantsCount=\(participantsCount)")
            }

            if case .error(let message) = parsedMessage,
               case .connecting = connectionState {
                pendingConnectionError = mapServerError(message)
                logWarning("received server error while connecting: \(message)")
            }

            broadcast(.message(parsedMessage))
        }
    }

    private func handleSocketFailure(_ error: QuizParticipationServiceError) async {
        logError("socket failure: \(error)")
        if case .connecting = connectionState {
            pendingConnectionError = error
        }

        broadcast(.failure(streamFailure(for: error)))
        await disconnect()
    }

    private func waitForConnectedPayload() async throws -> QuizConnectedPayload {
        logDebug("waiting for connected payload")
        let deadline = DispatchTime.now().uptimeNanoseconds + Constants.connectionTimeoutNanoseconds

        while Task.isCancelled == false {
            if let pendingConnectionError {
                logError("connected payload wait failed due to pending error: \(pendingConnectionError)")
                throw pendingConnectionError
            }

            if let lastConnectedPayload {
                logDebug("connected payload arrived while waiting")
                return lastConnectedPayload
            }

            if DispatchTime.now().uptimeNanoseconds >= deadline {
                logError("connected payload wait timed out")
                throw QuizParticipationServiceError.connectionTimeout
            }

            try? await Task.sleep(nanoseconds: Constants.connectionPollNanoseconds)
        }

        logWarning("connected payload wait cancelled because task closed")
        throw QuizParticipationServiceError.connectionClosed
    }

    private func sendPingIfConnected() async {
        guard let webSocketTask else {
            logDebug("ping skipped: websocket task missing")
            return
        }

        logDebug("sending websocket ping")
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                webSocketTask.sendPing { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            }
            logDebug("websocket ping succeeded")
        } catch {
            if Task.isCancelled {
                logDebug("ping cancelled")
                return
            }

            logError("websocket ping failed: \(error)")
            await handleSocketFailure(QuizParticipationServiceError.wrap(error))
        }
    }

    private func makeRequest(accessCode: String) async throws -> URLRequest {
        guard let token = await sessionManager.accessToken() else {
            logError("makeRequest failed: access token is missing")
            throw QuizParticipationServiceError.unauthorized
        }

        let url = try makeWebSocketURL(token: token, accessCode: accessCode)
        logDebug("websocket request URL prepared: \(maskedURLDescription(url))")
        return URLRequest(url: url)
    }

    private func makeWebSocketURL(token: String, accessCode: String) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            logError("makeWebSocketURL failed: invalid base URL \(baseURL.absoluteString)")
            throw QuizParticipationServiceError.invalidConfiguration
        }

        components.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components.path = normalizedPath(configuration.path)

        var queryItems = components.queryItems ?? []
        queryItems.append(URLQueryItem(name: configuration.tokenQueryName, value: token))
        queryItems.append(URLQueryItem(name: configuration.accessCodeQueryName, value: accessCode))
        components.queryItems = queryItems

        guard let url = components.url else {
            logError("makeWebSocketURL failed: URL components could not be resolved")
            throw QuizParticipationServiceError.invalidConfiguration
        }

        return url
    }

    private func normalizedPath(_ path: String) -> String {
        path.hasPrefix("/") ? path : "/\(path)"
    }

    private func parseIncomingMessage(_ text: String) -> QuizParticipationMessage {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dictionary = object as? [String: Any] else {
            logWarning("failed to parse incoming JSON into dictionary")
            return .unknown(type: "unknown", payloadSummary: nil, rawText: text)
        }

        let type = (dictionary["type"] as? String) ?? "unknown"
        let payload = dictionary["payload"] as? [String: Any]

        switch type {
        case "connected":
            let connectedPayload = QuizConnectedPayload(
                sessionId: payload?["session_id"] as? String,
                quizType: quizType(from: payload?["quiz_type"]),
                quizStatus: quizStatus(from: payload?["quiz_status"]),
                isCreator: boolValue(from: payload?["is_creator"]) ?? false
            )
            return .connected(connectedPayload)

        case "participants_update":
            let count = max(1, intValue(from: payload?["count"]) ?? 1)
            let actionRawValue = payload?["action"] as? String
            let updatePayload = QuizParticipantsUpdatePayload(
                action: actionRawValue.flatMap { QuizParticipantsUpdateAction(rawValue: $0) },
                userId: payload?["user_id"] as? String,
                user: parseParticipant((payload?["user"] as? [String: Any]) ?? [:]),
                count: count,
                participants: parseParticipants(from: payload?["participants"])
            )
            return .participantsUpdate(updatePayload)

        case "participants_list":
            let quiz = payload?["quiz"] as? [String: Any]
            let listPayload = QuizParticipantsListPayload(
                participants: parseParticipants(from: payload?["participants"]) ?? [],
                quizTitle: quiz?["title"] as? String
            )
            return .participantsList(listPayload)

        case "quiz_started":
            return .quizStarted(
                quizType: quizType(from: payload?["quiz_type"])
            )

        case "question":
            guard let questionPayload = parseQuestionPayload(from: payload) else {
                return .unknown(type: type, payloadSummary: formattedPayload(payload), rawText: text)
            }
            return .question(questionPayload)

        case "answer_progress":
            let answerProgressPayload = QuizAnswerProgressPayload(
                participantsAnswered: max(0, intValue(from: payload?["participants_answered"]) ?? 0),
                totalParticipants: max(0, intValue(from: payload?["total_participants"]) ?? 0)
            )
            return .answerProgress(answerProgressPayload)

        case "answer_result":
            guard let answerResultPayload = parseAnswerResultPayload(from: payload) else {
                return .unknown(type: type, payloadSummary: formattedPayload(payload), rawText: text)
            }
            return .answerResult(answerResultPayload)

        case "leaderboard":
            guard let leaderboardPayload = parseLeaderboardPayload(from: payload) else {
                return .unknown(type: type, payloadSummary: formattedPayload(payload), rawText: text)
            }
            return .leaderboard(leaderboardPayload)

        case "time_expired":
            let timeExpiredPayload = QuizTimeExpiredPayload(
                questionIndex: intValue(from: payload?["question_index"]) ?? 0
            )
            return .timeExpired(timeExpiredPayload)

        case "waiting_for_creator":
            let waitingPayload = QuizWaitingForCreatorPayload(
                questionIndex: intValue(from: payload?["question_index"]) ?? 0,
                reason: payload?["reason"] as? String
            )
            return .waitingForCreator(waitingPayload)

        case "quiz_finished":
            let finishedPayload = QuizFinishedPayload(
                finalScore: intValue(from: payload?["final_score"]),
                rank: intValue(from: payload?["rank"])
            )
            return .quizFinished(finishedPayload)

        case "error":
            let message = (payload?["message"] as? String) ?? "Неизвестная ошибка"
            return .error(message: message)

        default:
            return .unknown(
                type: type,
                payloadSummary: formattedPayload(payload),
                rawText: text
            )
        }
    }

    private func parseIncomingMessages(_ text: String) -> [QuizParticipationMessage] {
        let chunks = text
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false }

        guard chunks.isEmpty == false else {
            logWarning("incoming message was empty after normalization")
            return [.unknown(type: "unknown", payloadSummary: nil, rawText: text)]
        }

        if chunks.count > 1 {
            logDebug("incoming payload contains \(chunks.count) JSON chunks")
        }
        return chunks.map(parseIncomingMessage)
    }

    private func parseParticipants(from value: Any?) -> [QuizParticipant]? {
        guard let rawParticipants = value as? [[String: Any]] else {
            return nil
        }

        return rawParticipants.compactMap(parseParticipant)
    }

    private func applyParticipantsUpdateToCache(_ payload: QuizParticipantsUpdatePayload) {
        logDebug(
            "applyParticipantsUpdateToCache: action=\(payload.action?.rawValue ?? "nil"), " +
            "payloadCount=\(payload.count), currentParticipants=\(participants.count)"
        )
        participantsCount = max(1, max(payload.count, payload.participants?.count ?? participants.count))

        if let participants = payload.participants {
            self.participants = participants
            logDebug("participants cache replaced from payload: total=\(self.participants.count)")
            return
        }

        guard let action = payload.action else {
            return
        }

        let payloadUserId = payload.userId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let user = payload.user
        let userId = user?.userId?.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetUserId = userId?.isEmpty == false ? userId : (payloadUserId?.isEmpty == false ? payloadUserId : nil)

        switch action {
        case .joined:
            guard let user else {
                logWarning("participants_update joined ignored: missing user object")
                return
            }

            if let targetUserId,
               let existingIndex = participants.firstIndex(where: { participant in
                   participant.userId?.trimmingCharacters(in: .whitespacesAndNewlines) == targetUserId
               }) {
                participants[existingIndex] = user
                logDebug("participant updated in cache at index \(existingIndex); total=\(participants.count)")
                return
            }

            participants.append(user)
            logDebug("participant appended to cache; total=\(participants.count)")

        case .left:
            guard let targetUserId else {
                logWarning("participants_update left ignored: missing target user id")
                return
            }

            participants.removeAll { participant in
                participant.userId?.trimmingCharacters(in: .whitespacesAndNewlines) == targetUserId
            }
            logDebug("participant removed from cache; total=\(participants.count)")

        case .answered:
            logDebug("participants_update answered received (cache unchanged)")
            break
        }
    }

    private func parseParticipant(_ rawParticipant: [String: Any]) -> QuizParticipant? {
        let userId = rawParticipant["user_id"] as? String
        let firstName = rawParticipant["first_name"] as? String
        let lastName = rawParticipant["last_name"] as? String
        let email = rawParticipant["email"] as? String
        let avatarURL = rawParticipant["avatar_url"] as? String
        let isCreator = boolValue(from: rawParticipant["is_creator"]) ?? false

        let hasMeaningfulData = [userId, firstName, lastName, email, avatarURL]
            .contains { value in
                guard let value else { return false }
                return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }

        guard hasMeaningfulData || rawParticipant["is_creator"] != nil else {
            return nil
        }

        return QuizParticipant(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            avatarURL: avatarURL,
            isCreator: isCreator
        )
    }

    private func parseQuestionPayload(from payload: [String: Any]?) -> QuizQuestionPayload? {
        guard let payload,
              let rawQuestion = payload["question"] as? [String: Any] else {
            return nil
        }

        let question = QuizQuestionData(
            id: rawQuestion["id"] as? String,
            text: rawQuestion["text"] as? String,
            type: questionType(from: rawQuestion["type"]),
            options: rawQuestion["options"] as? [String] ?? [],
            orderIndex: intValue(from: rawQuestion["order_index"]),
            maxScore: intValue(from: rawQuestion["max_score"]),
            timeLimitSec: intValue(from: rawQuestion["time_limit_sec"])
        )

        return QuizQuestionPayload(
            question: question,
            questionIndex: intValue(from: payload["question_index"]) ?? 0,
            totalQuestions: max(1, intValue(from: payload["total_questions"]) ?? 1),
            timeLimitMs: int64Value(from: payload["time_limit_ms"]),
            serverTime: int64Value(from: payload["server_time"])
        )
    }

    private func parseAnswerResultPayload(from payload: [String: Any]?) -> QuizAnswerResultPayload? {
        guard let payload else { return nil }
        guard let isCorrect = boolValue(from: payload["is_correct"]),
              let score = intValue(from: payload["score"]),
              let timeSpentMs = int64Value(from: payload["time_spent_ms"]),
              let totalScore = intValue(from: payload["total_score"]) else {
            return nil
        }

        return QuizAnswerResultPayload(
            userId: payload["user_id"] as? String,
            isCorrect: isCorrect,
            score: score,
            timeSpentMs: timeSpentMs,
            totalScore: totalScore
        )
    }

    private func parseLeaderboardPayload(from payload: [String: Any]?) -> QuizLeaderboardPayload? {
        guard let payload,
              let rawEntries = payload["leaderboard"] as? [[String: Any]] else {
            return nil
        }

        let entries = rawEntries.compactMap { rawEntry -> QuizLeaderboardEntryPayload? in
            guard let user = parseParticipant(rawEntry["user"] as? [String: Any] ?? [:]),
                  let rank = intValue(from: rawEntry["rank"]),
                  let score = intValue(from: rawEntry["score"]) else {
                return nil
            }

            return QuizLeaderboardEntryPayload(
                user: user,
                rank: rank,
                score: score,
                isAnswered: boolValue(from: rawEntry["is_answered"]) ?? false
            )
        }

        let rawQuestionStats = payload["questions_stats"]
        let questionStats = parseQuestionStatsPayload(from: rawQuestionStats as? [String: Any])
        let answerOptionStats = parseAnswerOptionStats(from: rawQuestionStats)

        return QuizLeaderboardPayload(
            leaderboard: entries,
            questionStats: questionStats,
            answerOptionStats: answerOptionStats,
            canContinue: boolValue(from: payload["can_continue"]) ?? false
        )
    }

    private func parseAnswerOptionStats(from payload: Any?) -> [QuizAnswerOptionStatsPayload] {
        let rawOptions: [[String: Any]]

        if let statsArray = payload as? [[String: Any]] {
            rawOptions = statsArray
        } else if let statsObject = payload as? [String: Any],
                  let options = statsObject["options"] as? [[String: Any]] {
            rawOptions = options
        } else {
            rawOptions = []
        }

        return rawOptions.compactMap { rawOption in
            guard let option = rawOption["option"] as? String,
                  let count = intValue(from: rawOption["count"]) else {
                return nil
            }

            return QuizAnswerOptionStatsPayload(
                option: option,
                count: count
            )
        }
    }

    private func parseQuestionStatsPayload(from payload: [String: Any]?) -> QuizQuestionStatsPayload? {
        guard let payload else {
            return nil
        }

        let rawOptions = payload["options"]
        let parsedOptions: [String]

        if let options = rawOptions as? [String] {
            parsedOptions = options
        } else if let options = rawOptions as? [[String: Any]] {
            parsedOptions = options.compactMap { option in
                option["option"] as? String
            }
        } else {
            parsedOptions = []
        }

        return QuizQuestionStatsPayload(
            text: payload["text"] as? String,
            type: questionType(from: payload["type"]),
            options: parsedOptions,
            orderIndex: intValue(from: payload["order_index"]),
            maxScore: intValue(from: payload["max_score"]),
            timeLimitSec: intValue(from: payload["time_limit_sec"])
        )
    }

    private func questionType(from value: Any?) -> QuestionType? {
        guard let rawValue = value as? String else { return nil }
        return QuestionType(rawValue: rawValue)
    }

    private func boolValue(from value: Any?) -> Bool? {
        if let bool = value as? Bool {
            return bool
        }

        if let string = value as? String {
            return NSString(string: string).boolValue
        }

        return nil
    }

    private func int64Value(from value: Any?) -> Int64? {
        if let int64 = value as? Int64 {
            return int64
        }

        if let int = value as? Int {
            return Int64(int)
        }

        if let string = value as? String {
            return Int64(string)
        }

        return nil
    }

    private func intValue(from value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }

    private func quizType(from value: Any?) -> QuizType? {
        guard let rawValue = value as? String else { return nil }
        return QuizType(rawValue: rawValue)
    }

    private func quizStatus(from value: Any?) -> QuizStatus? {
        guard let rawValue = value as? String else { return nil }
        return QuizStatus(rawValue: rawValue)
    }

    private func formattedPayload(_ payload: Any?) -> String? {
        guard let payload else { return nil }

        if JSONSerialization.isValidJSONObject(payload),
           let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]),
           let payloadText = String(data: payloadData, encoding: .utf8) {
            return payloadText
        }

        if payload is NSNull {
            return "null"
        }

        return String(describing: payload)
    }

    private func mapServerError(_ message: String) -> QuizParticipationServiceError {
        let normalizedMessage = message.lowercased()

        if normalizedMessage.contains("invalid") && normalizedMessage.contains("code") {
            return .invalidCode
        }

        if normalizedMessage.contains("not found") {
            return .invalidCode
        }

        if normalizedMessage.contains("unauthorized") || normalizedMessage.contains("token") {
            return .unauthorized
        }

        return .unknown
    }

    private func streamFailure(for error: QuizParticipationServiceError) -> QuizParticipationStreamFailure {
        switch error {
        case .offline:
            return .offline
        case .unauthorized:
            return .unauthorized
        case .connectionClosed:
            return .connectionClosed
        case .connectionTimeout:
            return .connectionTimeout
        default:
            return .unknown
        }
    }

    private func updateConnectionState(_ newValue: QuizParticipationConnectionState) {
        guard connectionState != newValue else {
            return
        }

        let oldValue = connectionState
        connectionState = newValue
        logInfo("connection state changed: \(connectionStateDescription(oldValue)) -> \(connectionStateDescription(newValue))")
        broadcast(.connectionChanged(newValue))
    }

    private func broadcast(_ event: QuizParticipationEvent) {
        logDebug("broadcast event to \(subscribers.count) subscribers: \(eventDescription(event))")
        subscribers.values.forEach { continuation in
            continuation.yield(event)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
        logDebug("subscriber removed: id=\(id.uuidString), total=\(subscribers.count)")
    }

    private func logOut(type: String, payloadSummary: String) {
        logInfo("OUT type=\(type) payload=\(payloadSummary)")
    }

    private func logInRaw(_ text: String) {
        logInfo("IN raw=\(truncated(text))")
    }

    private func logInParsed(_ message: QuizParticipationMessage) {
        logInfo("IN parsed=\(messageDescription(message))")
    }

    private func logDebug(_ message: String) {
        log(level: "DEBUG", message)
    }

    private func logInfo(_ message: String) {
        log(level: "INFO", message)
    }

    private func logWarning(_ message: String) {
        log(level: "WARN", message)
    }

    private func logError(_ message: String) {
        log(level: "ERROR", message)
    }

    private func log(level: String, _ message: String) {
        logger("[QuizWS][\(level)][\(timestampString())] \(message)")
    }

    private func timestampString() -> String {
        Self.logDateFormatter.string(from: Date())
    }

    private func truncated(_ message: String) -> String {
        if message.count <= Constants.maxLogMessageLength {
            return message
        }

        let index = message.index(message.startIndex, offsetBy: Constants.maxLogMessageLength)
        return "\(message[..<index])...(truncated)"
    }

    private func maskedURLDescription(_ url: URL?) -> String {
        guard let url,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "nil"
        }

        components.queryItems = components.queryItems?.map { item in
            if item.name == configuration.tokenQueryName {
                return URLQueryItem(name: item.name, value: maskToken(item.value))
            }
            return item
        }

        return components.url?.absoluteString ?? url.absoluteString
    }

    private func maskToken(_ token: String?) -> String {
        guard let token, token.isEmpty == false else {
            return "nil"
        }

        let visiblePrefix = min(6, token.count)
        let visibleSuffix = min(4, max(0, token.count - visiblePrefix))
        let prefix = token.prefix(visiblePrefix)
        let suffix = token.suffix(visibleSuffix)
        return "\(prefix)...\(suffix)"
    }

    private func connectionStateDescription(_ state: QuizParticipationConnectionState) -> String {
        switch state {
        case .disconnected:
            return "disconnected"
        case .connecting(let accessCode):
            return "connecting(accessCode=\(accessCode))"
        case .connected(let accessCode):
            return "connected(accessCode=\(accessCode))"
        }
    }

    private func eventDescription(_ event: QuizParticipationEvent) -> String {
        switch event {
        case .connectionChanged(let state):
            return "connectionChanged(\(connectionStateDescription(state)))"
        case .message(let message):
            return "message(\(messageDescription(message)))"
        case .failure(let failure):
            return "failure(\(failure))"
        }
    }

    private func messageDescription(_ message: QuizParticipationMessage) -> String {
        switch message {
        case .connected(let payload):
            return "connected(sessionId=\(payload.sessionId ?? "nil"), isCreator=\(payload.isCreator), status=\(payload.quizStatus?.rawValue ?? "nil"))"
        case .participantsUpdate(let payload):
            return "participants_update(action=\(payload.action?.rawValue ?? "nil"), userId=\(payload.userId ?? payload.user?.userId ?? "nil"), count=\(payload.count))"
        case .participantsList(let payload):
            return "participants_list(participants=\(payload.participants.count), title=\(payload.quizTitle ?? "nil"))"
        case .quizStarted(let quizType):
            return "quiz_started(type=\(quizType?.rawValue ?? "nil"))"
        case .question(let payload):
            return "question(index=\(payload.questionIndex), total=\(payload.totalQuestions), id=\(payload.question.id ?? "nil"), type=\(payload.question.type?.rawValue ?? "nil"))"
        case .answerProgress(let payload):
            return "answer_progress(answered=\(payload.participantsAnswered), total=\(payload.totalParticipants))"
        case .answerResult(let payload):
            return "answer_result(userId=\(payload.userId ?? "nil"), score=\(payload.score), totalScore=\(payload.totalScore), correct=\(payload.isCorrect))"
        case .leaderboard(let payload):
            return "leaderboard(entries=\(payload.leaderboard.count), optionStats=\(payload.answerOptionStats.count), canContinue=\(payload.canContinue))"
        case .timeExpired(let payload):
            return "time_expired(questionIndex=\(payload.questionIndex))"
        case .waitingForCreator(let payload):
            return "waiting_for_creator(questionIndex=\(payload.questionIndex), reason=\(payload.reason ?? "nil"))"
        case .quizFinished(let payload):
            return "quiz_finished(finalScore=\(payload.finalScore.map(String.init) ?? "nil"), rank=\(payload.rank.map(String.init) ?? "nil"))"
        case .error(let message):
            return "error(message=\(message))"
        case .unknown(let type, let payloadSummary, let rawText):
            return "unknown(type=\(type), payloadSummary=\(payloadSummary ?? "nil"), raw=\(truncated(rawText)))"
        }
    }
}

// MARK: - Models
private extension QuizParticipationServiceImpl {
    struct OutgoingMessage<Payload: Encodable>: Encodable {
        let type: String
        let payload: Payload?

        private enum CodingKeys: String, CodingKey {
            case type
            case payload
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encodeIfPresent(payload, forKey: .payload)
        }
    }

    struct EmptyPayload: Encodable {
    }

    struct AnswerPayload: Encodable {
        let questionId: String
        let answer: String
        let timeSpentMs: Int64?

        private enum CodingKeys: String, CodingKey {
            case questionId = "question_id"
            case answer
            case timeSpentMs = "time_spent_ms"
        }
    }
}

// MARK: - QuizParticipationServiceError
enum QuizParticipationServiceError: Error, Sendable, Equatable {
    case unauthorized
    case invalidConfiguration
    case invalidCode
    case offline
    case notConnected
    case connectionClosed
    case connectionTimeout
    case encodingFailed
    case unknown

    static func wrap(_ error: Error) -> QuizParticipationServiceError {
        if let serviceError = error as? QuizParticipationServiceError {
            return serviceError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .offline
            case .userAuthenticationRequired:
                return .unauthorized
            case .networkConnectionLost:
                return .connectionClosed
            case .badServerResponse:
                return .invalidCode
            case .timedOut:
                return .connectionTimeout
            default:
                return .unknown
            }
        }

        return .unknown
    }
}
