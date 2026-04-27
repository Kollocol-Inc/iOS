//
//  ProfileLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Foundation
import UIKit
import Testing
@testable import Kollocol

@MainActor
struct ProfileLogicTests {
    @Test
    func fetchUserProfileSuccessPresentsProfile() async throws {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        let user = try makeUserDTO(id: "profile-user")
        await userService.setUserProfileResult(user)

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.fetchUserProfile()

        #expect(await presenter.userProfileIDs() == ["profile-user"])
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func fetchNotificationsSuccessMapsAndPresentsSettings() async throws {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        await userService.setNotificationsResult(
            try makeNotificationsDTO(
                deadlineReminder: "3h",
                groupInvites: true,
                newQuizzes: false,
                quizResults: true
            )
        )

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.fetchNotificationsSettings()

        let settings = await presenter.lastNotificationsSettings()
        #expect(settings?.deadlineReminder == .threeHours)
        #expect(settings?.groupInvites == true)
        #expect(settings?.newQuizzes == false)
        #expect(settings?.quizResults == true)
    }

    @Test
    func updateNewQuizzesNotificationSuccessUsesCurrentSettings() async throws {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        await userService.setNotificationsResult(
            try makeNotificationsDTO(
                deadlineReminder: "1h",
                groupInvites: true,
                newQuizzes: false,
                quizResults: false
            )
        )
        await userService.setUpdateNotificationsResult(
            try makeNotificationsDTO(
                deadlineReminder: "1h",
                groupInvites: true,
                newQuizzes: true,
                quizResults: false
            )
        )

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.fetchNotificationsSettings()
        await logic.updateNewQuizzesNotification(isEnabled: true)

        let request = await userService.lastUpdateNotificationsRequest()
        #expect(request?.deadlineReminder == "1h")
        #expect(request?.groupInvites == true)
        #expect(request?.newQuizzes == true)
        #expect(request?.quizResults == false)

        let latestSettings = await presenter.lastNotificationsSettings()
        #expect(latestSettings?.newQuizzes == true)
        #expect(await presenter.serviceErrors().isEmpty)
    }

    @Test
    func updateNotificationsFailureRollsBackAndPresentsError() async throws {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        let baseline = try makeNotificationsDTO(
            deadlineReminder: "6h",
            groupInvites: true,
            newQuizzes: false,
            quizResults: true
        )
        await userService.setNotificationsResult(baseline)
        await userService.setUpdateNotificationsError(.offline)

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.fetchNotificationsSettings()
        await logic.updateGroupInvitesNotification(isEnabled: false)

        #expect(await presenter.notificationsSettingsCount() == 2)
        let rolledBack = await presenter.lastNotificationsSettings()
        #expect(rolledBack?.deadlineReminder == .sixHours)
        #expect(rolledBack?.groupInvites == true)
        #expect(rolledBack?.newQuizzes == false)
        #expect(rolledBack?.quizResults == true)

        let errors = await presenter.serviceErrors()
        #expect(errors.count == 1)
        #expect(isUserServiceError(errors.first, .offline))
    }

    @Test
    func uploadAvatarFailureReturnsFalseAndPresentsError() async {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        await userService.setUploadAvatarError(.badRequest)

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        let isSuccess = await logic.uploadAvatar(data: Data([0xAA]))

        #expect(isSuccess == false)
        #expect(await userService.uploadCallsCount() == 1)
        let errors = await presenter.avatarUploadErrors()
        #expect(errors.count == 1)
        #expect(isUserServiceError(errors.first, .badRequest))
    }

    @Test
    func deleteAvatarFailurePresentsDeleteError() async {
        let presenter = ProfilePresenterSpy()
        let userService = ProfileUserServiceMock()
        await userService.setDeleteAvatarError(.server)

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: makeSessionManager().manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.deleteAvatar()

        let errors = await presenter.avatarDeleteErrors()
        #expect(errors.count == 1)
        #expect(isUserServiceError(errors.first, .server))
    }

    @Test
    func fetchAndUpdateThemeAndLanguageOptions() async {
        let presenter = ProfilePresenterSpy()
        let userDefaults = ProfileUserDefaultsServiceMock()
        userDefaults.appThemePreference = .dark
        userDefaults.appLanguagePreference = .en

        let logic = ProfileLogic(
            presenter: presenter,
            userService: ProfileUserServiceMock(),
            sessionManager: makeSessionManager().manager,
            udService: userDefaults
        )

        await logic.fetchThemeOption()
        await logic.fetchLanguageOption()
        await logic.updateThemeOption(.light)
        await logic.updateLanguageOption(.russian)

        #expect(userDefaults.appThemePreference == .light)
        #expect(userDefaults.appLanguagePreference == .ru)
        #expect(await presenter.themeOptions() == [.dark, .light])
        #expect(await presenter.languageOptions() == [.english, .russian])
    }

    @Test
    func logoutAutoConfirmationTriggersForcedLogout() async {
        let presenter = ProfilePresenterSpy()
        await presenter.setAutoConfirmLogout(true)
        let userService = ProfileUserServiceMock()
        let sessionManager = makeSessionManager()

        let logic = ProfileLogic(
            presenter: presenter,
            userService: userService,
            sessionManager: sessionManager.manager,
            udService: ProfileUserDefaultsServiceMock()
        )

        await logic.logout()
        try? await Task.sleep(nanoseconds: 50_000_000)

        #expect(await presenter.logoutConfirmationCallsCount() == 1)
        #expect(await sessionManager.store.clearCallsCount() == 1)
        #expect(await sessionManager.logoutProbe.callsCount() == 1)
    }
}

private actor ProfilePresenterSpy: ProfilePresenter {
    private var userProfilesStorage: [UserDTO] = []
    private var notificationsSettingsStorage: [ProfileModels.NotificationsSettings] = []
    private var themeOptionsStorage: [ProfileModels.ThemeOption] = []
    private var languageOptionsStorage: [ProfileModels.LanguageOption] = []
    private var profileUpdateErrorsStorage: [UserServiceError] = []
    private var avatarUploadErrorsStorage: [UserServiceError] = []
    private var avatarDeleteErrorsStorage: [UserServiceError] = []
    private var serviceErrorsStorage: [UserServiceError] = []
    private var logoutConfirmationCalls = 0
    private var autoConfirmLogout = false

    func setAutoConfirmLogout(_ value: Bool) {
        autoConfirmLogout = value
    }

    func presentUserProfile(_ user: UserDTO) async {
        userProfilesStorage.append(user)
    }

    func presentNotificationsSettings(_ settings: ProfileModels.NotificationsSettings) async {
        notificationsSettingsStorage.append(settings)
    }

    func presentThemeOption(_ option: ProfileModels.ThemeOption) async {
        themeOptionsStorage.append(option)
    }

    func presentLanguageOption(_ option: ProfileModels.LanguageOption) async {
        languageOptionsStorage.append(option)
    }

    func presentProfileUpdateError(_ error: UserServiceError) async {
        profileUpdateErrorsStorage.append(error)
    }

    func presentAvatarUploadError(_ error: UserServiceError) async {
        avatarUploadErrorsStorage.append(error)
    }

    func presentAvatarDeleteError(_ error: UserServiceError) async {
        avatarDeleteErrorsStorage.append(error)
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
    }

    func presentServiceError(_ error: UserServiceError) async {
        serviceErrorsStorage.append(error)
    }

    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        logoutConfirmationCalls += 1
        guard autoConfirmLogout else { return }

        await MainActor.run {
            onConfirm()
        }
    }

    func userProfileIDs() -> [String?] {
        userProfilesStorage.map(\.id)
    }

    func notificationsSettingsCount() -> Int {
        notificationsSettingsStorage.count
    }

    func lastNotificationsSettings() -> ProfileModels.NotificationsSettings? {
        notificationsSettingsStorage.last
    }

    func themeOptions() -> [ProfileModels.ThemeOption] {
        themeOptionsStorage
    }

    func languageOptions() -> [ProfileModels.LanguageOption] {
        languageOptionsStorage
    }

    func avatarUploadErrors() -> [UserServiceError] {
        avatarUploadErrorsStorage
    }

    func avatarDeleteErrors() -> [UserServiceError] {
        avatarDeleteErrorsStorage
    }

    func serviceErrors() -> [UserServiceError] {
        serviceErrorsStorage
    }

    func logoutConfirmationCallsCount() -> Int {
        logoutConfirmationCalls
    }
}

private actor ProfileUserServiceMock: UserService {
    private var userProfileResult: UserDTO?
    private var userProfileError: UserServiceError?
    private var notificationsResult: NotificationsSettingsDTO?
    private var notificationsError: UserServiceError?
    private var updateNotificationsResult: NotificationsSettingsDTO?
    private var updateNotificationsError: UserServiceError?
    private var updateNotificationsRequestsStorage: [
        (deadlineReminder: String, groupInvites: Bool, newQuizzes: Bool, quizResults: Bool)
    ] = []
    private var uploadAvatarError: UserServiceError?
    private var deleteAvatarError: UserServiceError?
    private var uploadCalls = 0

    func setUserProfileResult(_ user: UserDTO) {
        userProfileResult = user
    }

    func setUserProfileError(_ error: UserServiceError?) {
        userProfileError = error
    }

    func setNotificationsResult(_ dto: NotificationsSettingsDTO) {
        notificationsResult = dto
    }

    func setNotificationsError(_ error: UserServiceError?) {
        notificationsError = error
    }

    func setUpdateNotificationsResult(_ dto: NotificationsSettingsDTO) {
        updateNotificationsResult = dto
    }

    func setUpdateNotificationsError(_ error: UserServiceError?) {
        updateNotificationsError = error
    }

    func setUploadAvatarError(_ error: UserServiceError?) {
        uploadAvatarError = error
    }

    func setDeleteAvatarError(_ error: UserServiceError?) {
        deleteAvatarError = error
    }

    func uploadCallsCount() -> Int {
        uploadCalls
    }

    func lastUpdateNotificationsRequest() -> (
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    )? {
        updateNotificationsRequestsStorage.last
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
        uploadCalls += 1
        if let uploadAvatarError {
            throw uploadAvatarError
        }
    }

    func getNotifications() async throws -> NotificationsSettingsDTO {
        if let notificationsError {
            throw notificationsError
        }
        guard let notificationsResult else {
            throw UserServiceError.unknown
        }
        return notificationsResult
    }

    func updateNotifications(
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    ) async throws -> NotificationsSettingsDTO {
        updateNotificationsRequestsStorage.append((deadlineReminder, groupInvites, newQuizzes, quizResults))

        if let updateNotificationsError {
            throw updateNotificationsError
        }

        guard let updateNotificationsResult else {
            throw UserServiceError.unknown
        }

        return updateNotificationsResult
    }

    func register(name: String, surname: String) async throws {
    }

    func deleteAvatar() async throws {
        if let deleteAvatarError {
            throw deleteAvatarError
        }
    }
}

private final class ProfileUserDefaultsServiceMock: UserDefaultsService {
    var isRegistered = false
    var appThemePreference: AppThemePreference = .system
    var appLanguagePreference: AppLanguagePreference = .system

    private var storage: [UserDefaultsKey: Any] = [:]

    func set<T>(_ value: T?, for key: UserDefaultsKey) {
        storage[key] = value
    }

    func value<T>(for key: UserDefaultsKey) -> T? {
        storage[key] as? T
    }

    func remove(_ key: UserDefaultsKey) {
        storage[key] = nil
    }

    func exists(_ key: UserDefaultsKey) -> Bool {
        storage[key] != nil
    }
}

private actor ProfileTokenStoreMock: TokenStoring {
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

private struct ProfileRefresherMock: TokenRefreshing {
    func refresh(using refreshToken: String) async throws -> TokenPair {
        TokenPair(accessToken: "access", refreshToken: "refresh")
    }
}

@MainActor
private final class ProfileLogoutProbe {
    private(set) var calls = 0

    func mark() {
        calls += 1
    }
}

private actor ProfileLogoutProbeAccessor {
    private let probe: ProfileLogoutProbe

    init(probe: ProfileLogoutProbe) {
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
    store: ProfileTokenStoreMock,
    logoutProbe: ProfileLogoutProbeAccessor
) {
    let store = ProfileTokenStoreMock()
    let refresher = ProfileRefresherMock()
    let probe = ProfileLogoutProbe()
    let probeAccessor = ProfileLogoutProbeAccessor(probe: probe)

    let manager = SessionManager(
        store: store,
        refresher: refresher,
        onForcedLogout: {
            probe.mark()
        }
    )

    return (manager, store, probeAccessor)
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

private func makeNotificationsDTO(
    deadlineReminder: String,
    groupInvites: Bool,
    newQuizzes: Bool,
    quizResults: Bool
) throws -> NotificationsSettingsDTO {
    let json = """
    {
      "deadline_reminder": "\(deadlineReminder)",
      "group_invites": \(groupInvites),
      "new_quizzes": \(newQuizzes),
      "quiz_results": \(quizResults),
      "user_id": "user-1"
    }
    """

    return try JSONDecoder().decode(NotificationsSettingsDTO.self, from: Data(json.utf8))
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
