//
//  MainLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct MainLogicTests {
    @Test
    func fetchUserProfileSuccessPresentsUserProfile() async throws {
        let presenter = MainPresenterSpy()
        let userService = MainUserServiceMock()
        let user = try makeUserDTO(id: "user-1")
        await userService.setUserProfileResult(user)

        let logic = MainLogic(
            presenter: presenter,
            userService: userService,
            quizService: MainQuizServiceMock(),
            quizParticipationService: MainQuizParticipationServiceMock()
        )

        await logic.fetchUserProfile()

        #expect(await presenter.userProfileIDs() == ["user-1"])
        #expect(await presenter.userServiceErrors().isEmpty)
    }

    @Test
    func fetchQuizzesSuccessPresentsParticipatingAndHosting() async {
        let presenter = MainPresenterSpy()
        let quizService = MainQuizServiceMock()

        let participating = [
            ParticipatingInstance(instance: makeQuizInstance(id: "p1", accessCode: "P1", quizType: .sync), sessionStatus: .joined),
            ParticipatingInstance(instance: nil, sessionStatus: .inProgress)
        ]
        let hosting = [makeQuizInstance(id: "h1", accessCode: "H1", quizType: .async)]
        await quizService.setParticipatingResult(participating)
        await quizService.setHostingResult(hosting)

        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: quizService,
            quizParticipationService: MainQuizParticipationServiceMock()
        )

        await logic.fetchQuizzes()

        #expect(logic.participatingInstances.count == 2)
        #expect(logic.hostingInstances.count == 1)
        #expect(await presenter.presentedQuizzesCount() == 1)
        #expect(await presenter.lastParticipatingCount() == 1)
        #expect(await presenter.lastHostingCount() == 1)
        #expect(await presenter.quizServiceErrors().isEmpty)
    }

    @Test
    func joinQuizAsyncGuestWithoutSkipPresentsAsyncConfirmation() async {
        let presenter = MainPresenterSpy()
        let participationService = MainQuizParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session-1",
                quizType: .async,
                quizStatus: .active,
                isCreator: false
            )
        )
        await participationService.setQuizTitle("Physics")

        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: participationService
        )

        await logic.joinQuiz(code: "ROOM42", skipAsyncConfirmation: false)

        #expect(await participationService.connectRequests() == ["ROOM42"])
        #expect(await participationService.disconnectCallsCount() == 1)
        #expect(await presenter.asyncConfirmationCallsCount() == 1)
        #expect(await presenter.lastAsyncConfirmationAccessCode() == "ROOM42")
        #expect(await presenter.lastAsyncConfirmationQuizTitle() == "Physics")
        #expect(await presenter.joinSuccessCodes().isEmpty)
    }

    @Test
    func joinQuizSkipAsyncConfirmationPresentsJoinSuccess() async {
        let presenter = MainPresenterSpy()
        let participationService = MainQuizParticipationServiceMock()
        await participationService.setConnectedPayload(
            QuizConnectedPayload(
                sessionId: "session-2",
                quizType: .async,
                quizStatus: .active,
                isCreator: false
            )
        )

        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: participationService
        )

        await logic.joinQuiz(code: "ROOM43", skipAsyncConfirmation: true)

        #expect(await presenter.joinSuccessCodes() == ["ROOM43"])
        #expect(await presenter.asyncConfirmationCallsCount() == 0)
        #expect(await participationService.disconnectCallsCount() == 0)
    }

    @Test
    func joinQuizFailurePresentsJoinError() async {
        let presenter = MainPresenterSpy()
        let participationService = MainQuizParticipationServiceMock()
        await participationService.setConnectError(.invalidCode)

        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: participationService
        )

        await logic.joinQuiz(code: "WRONG", skipAsyncConfirmation: false)

        let errors = await presenter.joinErrors()
        #expect(errors.count == 1)
        #expect(isQuizParticipationError(errors.first, .invalidCode))
        #expect(await presenter.joinSuccessCodes().isEmpty)
    }

    @Test
    func handleQuizCardTapHostingAsyncRoutesParticipantsOverview() async {
        let presenter = MainPresenterSpy()
        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: MainQuizParticipationServiceMock()
        )
        logic.hostingInstances = [
            makeQuizInstance(id: "instance-1", accessCode: nil, quizType: .async)
        ]

        await logic.handleQuizCardTap(
            QuizInstanceViewData(
                accessCode: nil,
                deadline: nil,
                id: "  instance-1  ",
                quizType: .async,
                status: .active,
                title: "  Async host quiz ",
                totalQuestions: nil,
                totalTime: nil
            )
        )

        let payloads = await presenter.participantsOverviewPayloads()
        #expect(payloads.count == 1)
        #expect(payloads.first?.instanceId == "instance-1")
        #expect(payloads.first?.quizTitle == "Async host quiz")
        #expect(payloads.first?.mode == .asyncState)
    }

    @Test
    func handleQuizCardTapGuestAsyncPresentsAsyncStartConfirmation() async {
        let presenter = MainPresenterSpy()
        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: MainQuizParticipationServiceMock()
        )

        await logic.handleQuizCardTap(
            QuizInstanceViewData(
                accessCode: "  AC-1  ",
                deadline: nil,
                id: "guest-1",
                quizType: .async,
                status: .active,
                title: "   ",
                totalQuestions: nil,
                totalTime: nil
            )
        )

        #expect(await presenter.asyncConfirmationCallsCount() == 1)
        #expect(await presenter.lastAsyncConfirmationAccessCode() == "AC-1")
        #expect(await presenter.lastAsyncConfirmationQuizTitle() == nil)
    }

    @Test
    func handleQuizCardTapSyncPresentsJoinConfirmation() async {
        let presenter = MainPresenterSpy()
        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: MainQuizParticipationServiceMock()
        )

        await logic.handleQuizCardTap(
            QuizInstanceViewData(
                accessCode: "  CODE-7  ",
                deadline: nil,
                id: "sync-1",
                quizType: .sync,
                status: .active,
                title: "  Chemistry  ",
                totalQuestions: nil,
                totalTime: nil
            )
        )

        #expect(await presenter.joinConfirmationCallsCount() == 1)
        #expect(await presenter.lastJoinConfirmationAccessCode() == "CODE-7")
        #expect(await presenter.lastJoinConfirmationQuizTitle() == "Chemistry")
    }

    @Test
    func routeToProfileAndQuizTypeTapForwardToPresenter() async {
        let presenter = MainPresenterSpy()
        let logic = MainLogic(
            presenter: presenter,
            userService: MainUserServiceMock(),
            quizService: MainQuizServiceMock(),
            quizParticipationService: MainQuizParticipationServiceMock()
        )

        await logic.routeToProfileScreen()
        await logic.handleQuizTypeTap(.async)

        #expect(await presenter.profileScreenCallsCount() == 1)
        #expect(await presenter.quizTypeInfoRequests() == [.async])
    }
}

private actor MainPresenterSpy: MainPresenter {
    private var userProfilesStorage: [UserDTO] = []
    private var quizzesPayloadsStorage: [(participating: [QuizInstance], hosting: [QuizInstance])] = []
    private var userServiceErrorsStorage: [UserServiceError] = []
    private var quizServiceErrorsStorage: [QuizServiceError] = []
    private var profileScreenCalls = 0
    private var participantsOverviewPayloadsStorage: [QuizParticipantsOverviewModels.InitialData] = []
    private var joinSuccessCodesStorage: [String] = []
    private var joinErrorsStorage: [QuizParticipationServiceError] = []
    private var joinConfirmationsStorage: [(accessCode: String, quizTitle: String)] = []
    private var asyncConfirmationsStorage: [(accessCode: String, quizTitle: String?)] = []
    private var quizTypeInfoRequestsStorage: [QuizType] = []

    func presentUserProfile(_ user: UserDTO) async {
        userProfilesStorage.append(user)
    }

    func presentQuizzes(participating: [QuizInstance], hosting: [QuizInstance]) async {
        quizzesPayloadsStorage.append((participating, hosting))
    }

    func presentServiceError(_ error: any UserFacingError) async {
        if let userError = error as? UserServiceError {
            userServiceErrorsStorage.append(userError)
            return
        }

        if let quizError = error as? QuizServiceError {
            quizServiceErrorsStorage.append(quizError)
        }
    }

    func presentProfileScreen() async {
        profileScreenCalls += 1
    }

    func presentQuizParticipantsOverview(_ initialData: QuizParticipantsOverviewModels.InitialData) async {
        participantsOverviewPayloadsStorage.append(initialData)
    }

    func presentJoinQuizSuccess(accessCode: String) async {
        joinSuccessCodesStorage.append(accessCode)
    }

    func presentJoinQuizError(_ error: QuizParticipationServiceError) async {
        joinErrorsStorage.append(error)
    }

    func presentJoinQuizConfirmation(accessCode: String, quizTitle: String) async {
        joinConfirmationsStorage.append((accessCode, quizTitle))
    }

    func presentAsyncQuizStartConfirmation(accessCode: String, quizTitle: String?) async {
        asyncConfirmationsStorage.append((accessCode, quizTitle))
    }

    func presentQuizTypeInfo(_ quizType: QuizType) async {
        quizTypeInfoRequestsStorage.append(quizType)
    }

    func userProfileIDs() -> [String?] {
        userProfilesStorage.map(\.id)
    }

    func presentedQuizzesCount() -> Int {
        quizzesPayloadsStorage.count
    }

    func lastParticipatingCount() -> Int {
        quizzesPayloadsStorage.last?.participating.count ?? 0
    }

    func lastHostingCount() -> Int {
        quizzesPayloadsStorage.last?.hosting.count ?? 0
    }

    func userServiceErrors() -> [UserServiceError] {
        userServiceErrorsStorage
    }

    func quizServiceErrors() -> [QuizServiceError] {
        quizServiceErrorsStorage
    }

    func profileScreenCallsCount() -> Int {
        profileScreenCalls
    }

    func participantsOverviewPayloads() -> [QuizParticipantsOverviewModels.InitialData] {
        participantsOverviewPayloadsStorage
    }

    func joinSuccessCodes() -> [String] {
        joinSuccessCodesStorage
    }

    func joinErrors() -> [QuizParticipationServiceError] {
        joinErrorsStorage
    }

    func joinConfirmationCallsCount() -> Int {
        joinConfirmationsStorage.count
    }

    func lastJoinConfirmationAccessCode() -> String? {
        joinConfirmationsStorage.last?.accessCode
    }

    func lastJoinConfirmationQuizTitle() -> String? {
        joinConfirmationsStorage.last?.quizTitle
    }

    func asyncConfirmationCallsCount() -> Int {
        asyncConfirmationsStorage.count
    }

    func lastAsyncConfirmationAccessCode() -> String? {
        asyncConfirmationsStorage.last?.accessCode
    }

    func lastAsyncConfirmationQuizTitle() -> String? {
        asyncConfirmationsStorage.last?.quizTitle
    }

    func quizTypeInfoRequests() -> [QuizType] {
        quizTypeInfoRequestsStorage
    }
}

private actor MainUserServiceMock: UserService {
    private var userProfileResult: UserDTO?
    private var userProfileError: UserServiceError?

    func setUserProfileResult(_ user: UserDTO) {
        userProfileResult = user
    }

    func setUserProfileError(_ error: UserServiceError?) {
        userProfileError = error
    }

    func getUserProfile() async throws -> UserDTO {
        if let userProfileError {
            throw userProfileError
        }

        guard let userProfileResult else {
            throw UserServiceError.unknown
        }

        return userProfileResult
    }

    func updateUserProfile(name: String, surname: String) async throws -> UserDTO {
        throw UserServiceError.unknown
    }

    func uploadAvatar(data: Data) async throws {
    }

    func getNotifications() async throws -> NotificationsSettingsDTO {
        throw UserServiceError.unknown
    }

    func updateNotifications(
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    ) async throws -> NotificationsSettingsDTO {
        throw UserServiceError.unknown
    }

    func register(name: String, surname: String) async throws {
    }

    func deleteAvatar() async throws {
    }
}

private actor MainQuizServiceMock: QuizService {
    private var participatingResult: [ParticipatingInstance] = []
    private var hostingResult: [QuizInstance] = []
    private var participatingError: QuizServiceError?
    private var hostingError: QuizServiceError?

    func setParticipatingResult(_ instances: [ParticipatingInstance]) {
        participatingResult = instances
    }

    func setHostingResult(_ instances: [QuizInstance]) {
        hostingResult = instances
    }

    func setParticipatingError(_ error: QuizServiceError?) {
        participatingError = error
    }

    func setHostingError(_ error: QuizServiceError?) {
        hostingError = error
    }

    func getParticipatingQuizzes() async throws -> [ParticipatingInstance] {
        if let participatingError {
            throw participatingError
        }
        return participatingResult
    }

    func getParticipatingQuizzes(sessionStatus: SessionStatus?) async throws -> [ParticipatingInstance] {
        try await getParticipatingQuizzes()
    }

    func getHostingQuizzes() async throws -> [QuizInstance] {
        if let hostingError {
            throw hostingError
        }
        return hostingResult
    }

    func getHostingQuizzes(status: QuizStatus?) async throws -> [QuizInstance] {
        try await getHostingQuizzes()
    }

    func getTemplates() async throws -> [QuizTemplate] {
        []
    }

    func getTemplate(by templateId: String) async throws -> QuizTemplate {
        throw QuizServiceError.unknown
    }

    func updateTemplate(by templateId: String, _ request: CreateTemplateRequest) async throws {
    }

    func createTemplate(_ request: CreateTemplateRequest) async throws {
    }

    func deleteTemplate(by templateId: String) async throws {
    }

    func createQuizInstance(_ request: CreateInstanceRequest) async throws -> String? {
        nil
    }

    func getQuizInstance(by instanceId: String) async throws -> QuizInstanceDetails {
        throw QuizServiceError.unknown
    }

    func deleteQuizInstance(by instanceId: String) async throws {
    }

    func getQuizInstanceParticipants(by instanceId: String) async throws -> [QuizInstanceParticipant] {
        []
    }

    func getParticipantAnswers(instanceId: String, participantId: String) async throws -> QuizParticipantAnswersDetails {
        throw QuizServiceError.unknown
    }

    func gradeParticipantAnswer(instanceId: String, request: GradeAnswerRequest) async throws {
    }

    func reviewParticipantAnswer(
        instanceId: String,
        request: ReviewAnswerRequest
    ) async throws -> QuizAnswerReviewSuggestion {
        throw QuizServiceError.unknown
    }

    func publishQuizResults(instanceId: String) async throws {
    }
}

private actor MainQuizParticipationServiceMock: QuizParticipationService {
    private var connectRequestsStorage: [String] = []
    private var connectError: QuizParticipationServiceError?
    private var connectedPayload: QuizConnectedPayload?
    private var quizTitle: String?
    private var disconnectCalls = 0

    func setConnectError(_ error: QuizParticipationServiceError?) {
        connectError = error
    }

    func setConnectedPayload(_ payload: QuizConnectedPayload?) {
        connectedPayload = payload
    }

    func setQuizTitle(_ title: String?) {
        quizTitle = title
    }

    func connectRequests() -> [String] {
        connectRequestsStorage
    }

    func disconnectCallsCount() -> Int {
        disconnectCalls
    }

    func connect(accessCode: String) async throws {
        connectRequestsStorage.append(accessCode)
        if let connectError {
            throw connectError
        }
    }

    func disconnect() async {
        disconnectCalls += 1
    }

    func currentConnectionState() -> QuizParticipationConnectionState {
        .disconnected
    }

    func currentConnectedPayload() -> QuizConnectedPayload? {
        connectedPayload
    }

    func currentQuizTitle() -> String? {
        quizTitle
    }

    func currentParticipantsCount() -> Int {
        1
    }

    func currentParticipants() -> [QuizParticipant] {
        []
    }

    func currentQuestionPayload() -> QuizQuestionPayload? {
        nil
    }

    func currentLeaderboardPayload() -> QuizLeaderboardPayload? {
        nil
    }

    func makeEventStream() -> AsyncStream<QuizParticipationEvent> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func startQuiz() async throws {
    }

    func sendAnswer(questionId: String, answer: String, timeSpentMs: Int64?) async throws {
    }

    func kickParticipant(email: String) async throws {
    }

    func sendCommand(type: String) async throws {
    }

    func sendCommand<Payload: Encodable>(type: String, payload: Payload?) async throws {
    }
}

private func makeQuizInstance(
    id: String,
    accessCode: String?,
    quizType: QuizType,
    status: QuizStatus = .active,
    title: String = "Quiz"
) -> QuizInstance {
    QuizInstance(
        accessCode: accessCode,
        createdAt: nil,
        deadline: nil,
        groupId: nil,
        hostUserId: nil,
        id: id,
        quizType: quizType,
        settings: nil,
        status: status,
        templateId: nil,
        title: title,
        totalQuestions: nil,
        totalTime: nil
    )
}

private func makeUserDTO(id: String) throws -> UserDTO {
    let json = """
    {
      "avatar_url": null,
      "created_at": "2026-01-01T00:00:00Z",
      "email": "\(id)@example.com",
      "first_name": "First",
      "id": "\(id)",
      "last_name": "Last",
      "updated_at": "2026-01-01T00:00:00Z"
    }
    """

    return try JSONDecoder().decode(UserDTO.self, from: Data(json.utf8))
}

private func isQuizParticipationError(
    _ actual: QuizParticipationServiceError?,
    _ expected: QuizParticipationServiceError
) -> Bool {
    switch (actual, expected) {
    case (.unauthorized, .unauthorized),
            (.invalidConfiguration, .invalidConfiguration),
            (.invalidCode, .invalidCode),
            (.quizAlreadyStarted, .quizAlreadyStarted),
            (.quizAlreadyFinished, .quizAlreadyFinished),
            (.offline, .offline),
            (.notConnected, .notConnected),
            (.connectionClosed, .connectionClosed),
            (.connectionTimeout, .connectionTimeout),
            (.encodingFailed, .encodingFailed),
            (.unknown, .unknown):
        return true
    default:
        return false
    }
}
