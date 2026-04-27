//
//  StartLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Testing
@testable import Kollocol

struct StartLogicTests {
    @Test
    func loginSuccessPresentsSuccess() async {
        let presenter = StartPresenterSpy()
        let authService = AuthServiceMock()
        let udService = UserDefaultsServiceMock()
        let logic = StartLogic(presenter: presenter, authService: authService, udService: udService)

        await logic.login(with: "user@example.com")

        let requestedEmails = await authService.loginRequests()
        #expect(requestedEmails == ["user@example.com"])
        #expect(await presenter.successEmails() == ["user@example.com"])
        #expect(await presenter.loginErrors().isEmpty)
    }

    @Test
    func loginFailurePresentsWrappedError() async {
        let presenter = StartPresenterSpy()
        let authService = AuthServiceMock()
        await authService.setLoginError(.tooManyRequests)
        let logic = StartLogic(
            presenter: presenter,
            authService: authService,
            udService: UserDefaultsServiceMock()
        )

        await logic.login(with: "user@example.com")

        let errors = await presenter.loginErrors()
        #expect(errors.count == 1)
        #expect(isAuthServiceError(errors.first, .tooManyRequests))
        #expect(await presenter.successEmails().isEmpty)
    }

    @Test
    func fetchLanguageOptionUsesStoredPreference() async {
        let presenter = StartPresenterSpy()
        let udService = UserDefaultsServiceMock()
        udService.appLanguagePreference = .en
        let logic = StartLogic(
            presenter: presenter,
            authService: AuthServiceMock(),
            udService: udService
        )

        await logic.fetchLanguageOption()

        let options = await presenter.languageOptions()
        #expect(options == [.english])
    }

    @Test
    func updateLanguageOptionPersistsAndPresents() async {
        let presenter = StartPresenterSpy()
        let udService = UserDefaultsServiceMock()
        let logic = StartLogic(
            presenter: presenter,
            authService: AuthServiceMock(),
            udService: udService
        )

        await logic.updateLanguageOption(.russian)

        #expect(udService.appLanguagePreference == .ru)
        #expect(await presenter.languageOptions() == [.russian])
    }
}

private actor StartPresenterSpy: StartPresenter {
    private var successEmailsStorage: [String] = []
    private var loginErrorsStorage: [AuthServiceError] = []
    private var languageOptionsStorage: [StartModels.LanguageOption] = []

    func presentLoginSuccess(email: String) async {
        successEmailsStorage.append(email)
    }

    func presentLoginError(_ error: AuthServiceError) async {
        loginErrorsStorage.append(error)
    }

    func presentLanguageOption(_ option: StartModels.LanguageOption) async {
        languageOptionsStorage.append(option)
    }

    func successEmails() -> [String] {
        successEmailsStorage
    }

    func loginErrors() -> [AuthServiceError] {
        loginErrorsStorage
    }

    func languageOptions() -> [StartModels.LanguageOption] {
        languageOptionsStorage
    }
}

private actor AuthServiceMock: AuthService {
    private var loginRequestsStorage: [String] = []
    private var loginError: AuthServiceError?

    func setLoginError(_ error: AuthServiceError?) {
        loginError = error
    }

    func loginRequests() -> [String] {
        loginRequestsStorage
    }

    func login(using email: String) async throws {
        loginRequestsStorage.append(email)
        if let loginError {
            throw loginError
        }
    }

    func logout() async throws {
    }

    func refreshToken(with token: String) async throws {
    }

    func resendCode(to email: String) async throws {
    }

    func verify(code: String, with email: String) async throws -> Bool {
        false
    }
}

private final class UserDefaultsServiceMock: UserDefaultsService {
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

private func isAuthServiceError(_ actual: AuthServiceError?, _ expected: AuthServiceError) -> Bool {
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
