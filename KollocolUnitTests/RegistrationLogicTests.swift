//
//  RegistrationLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import UIKit
import Testing
@testable import Kollocol

@MainActor
struct RegistrationLogicTests {
    @Test
    func registerWithoutAvatarSuccess() async {
        let presenter = RegistrationPresenterSpy()
        let userService = RegistrationUserServiceMock()
        let sessionManager = makeSessionManager()
        let logic = RegistrationLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager.manager
        )

        await logic.register(name: "Arsenii", surname: "Potiakin", avatarData: nil)

        #expect(await userService.uploadCalls().isEmpty)
        let registerCalls = await userService.registerCalls()
        #expect(registerCalls.count == 1)
        #expect(registerCalls.first?.0 == "Arsenii")
        #expect(registerCalls.first?.1 == "Potiakin")
        #expect(await presenter.successCallsCount() == 1)
        #expect(await presenter.registerErrors().isEmpty)
    }

    @Test
    func registerWithAvatarUploadFailureStopsFlow() async {
        let presenter = RegistrationPresenterSpy()
        let userService = RegistrationUserServiceMock()
        await userService.setUploadError(.badRequest)
        let sessionManager = makeSessionManager()
        let logic = RegistrationLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager.manager
        )

        await logic.register(name: "Arsenii", surname: "Potiakin", avatarData: Data([0x01]))

        let avatarErrors = await presenter.avatarUploadErrors()
        #expect(avatarErrors.count == 1)
        #expect(isUserServiceError(avatarErrors.first, .badRequest))
        #expect(await userService.registerCalls().isEmpty)
        #expect(await presenter.successCallsCount() == 0)
    }

    @Test
    func registerWithAvatarThenRegisterFailurePresentsRegisterError() async {
        let presenter = RegistrationPresenterSpy()
        let userService = RegistrationUserServiceMock()
        await userService.setRegisterError(.tooManyRequests)
        let sessionManager = makeSessionManager()
        let logic = RegistrationLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager.manager
        )

        await logic.register(name: "Arsenii", surname: "Potiakin", avatarData: Data([0xAA]))

        #expect(await userService.uploadCalls().count == 1)
        let registerCalls = await userService.registerCalls()
        #expect(registerCalls.count == 1)
        #expect(registerCalls.first?.0 == "Arsenii")
        #expect(registerCalls.first?.1 == "Potiakin")
        let registerErrors = await presenter.registerErrors()
        #expect(registerErrors.count == 1)
        #expect(isUserServiceError(registerErrors.first, .tooManyRequests))
        #expect(await presenter.successCallsCount() == 0)
    }

    @Test
    func cancelRegistrationForcesLogout() async {
        let presenter = RegistrationPresenterSpy()
        let userService = RegistrationUserServiceMock()
        let sessionManager = makeSessionManager()
        let logic = RegistrationLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager.manager
        )

        await logic.cancelRegistration()

        #expect(await sessionManager.store.clearCallsCount() == 1)
        #expect(await sessionManager.logoutProbe.callsCount() == 1)
    }
}

private actor RegistrationPresenterSpy: RegistrationPresenter {
    private var successCalls = 0
    private var registerErrorsStorage: [UserServiceError] = []
    private var avatarErrorsStorage: [UserServiceError] = []

    func presentSuccessfulRegister() async {
        successCalls += 1
    }

    func presentRegisterError(_ error: UserServiceError) async {
        registerErrorsStorage.append(error)
    }

    func presentAvatarUploadError(_ error: UserServiceError) async {
        avatarErrorsStorage.append(error)
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
    }

    func presentDeleteAvatarConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
    }

    func successCallsCount() -> Int {
        successCalls
    }

    func registerErrors() -> [UserServiceError] {
        registerErrorsStorage
    }

    func avatarUploadErrors() -> [UserServiceError] {
        avatarErrorsStorage
    }
}

private actor RegistrationUserServiceMock: UserService {
    private var uploadCallsStorage: [Data] = []
    private var registerCallsStorage: [(name: String, surname: String)] = []
    private var uploadError: UserServiceError?
    private var registerError: UserServiceError?

    func setUploadError(_ error: UserServiceError?) {
        uploadError = error
    }

    func setRegisterError(_ error: UserServiceError?) {
        registerError = error
    }

    func uploadCalls() -> [Data] {
        uploadCallsStorage
    }

    func registerCalls() -> [(String, String)] {
        registerCallsStorage.map { ($0.name, $0.surname) }
    }

    func getUserProfile() async throws -> UserDTO {
        throw UserServiceError.unknown
    }

    func updateUserProfile(name: String, surname: String) async throws -> UserDTO {
        throw UserServiceError.unknown
    }

    func uploadAvatar(data: Data) async throws {
        uploadCallsStorage.append(data)
        if let uploadError {
            throw uploadError
        }
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
        registerCallsStorage.append((name, surname))
        if let registerError {
            throw registerError
        }
    }

    func deleteAvatar() async throws {
    }
}

private actor TokenStoreMock: TokenStoring {
    private var clearCalls = 0

    func accessToken() async -> String? {
        nil
    }

    func refreshToken() async -> String? {
        nil
    }

    func set(_ pair: TokenPair) async {
    }

    func clear() async {
        clearCalls += 1
    }

    func clearCallsCount() -> Int {
        clearCalls
    }
}

private struct RefresherMock: TokenRefreshing {
    func refresh(using refreshToken: String) async throws -> TokenPair {
        TokenPair(accessToken: "access", refreshToken: "refresh")
    }
}

@MainActor
private final class LogoutProbe {
    private(set) var calls = 0

    func mark() {
        calls += 1
    }
}

private actor LogoutProbeAccessor {
    private let probe: LogoutProbe

    init(probe: LogoutProbe) {
        self.probe = probe
    }

    func callsCount() async -> Int {
        await MainActor.run {
            probe.calls
        }
    }
}

@MainActor
private func makeSessionManager() -> (
    manager: SessionManager,
    store: TokenStoreMock,
    logoutProbe: LogoutProbeAccessor
) {
    let store = TokenStoreMock()
    let refresher = RefresherMock()
    let probe = LogoutProbe()
    let probeAccessor = LogoutProbeAccessor(probe: probe)

    let manager = SessionManager(
        store: store,
        refresher: refresher,
        onForcedLogout: {
            probe.mark()
        }
    )

    return (manager, store, probeAccessor)
}

private func isUserServiceError(_ actual: UserServiceError?, _ expected: UserServiceError) -> Bool {
    switch (actual, expected) {
    case (.badRequest, .badRequest),
            (.tooManyRequests, .tooManyRequests),
            (.unauthorized, .unauthorized),
            (.offline, .offline),
            (.server, .server),
            (.unknown, .unknown):
        return true
    default:
        return false
    }
}
