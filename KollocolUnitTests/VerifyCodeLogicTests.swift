//
//  VerifyCodeLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 27.04.2026.
//

import Testing
@testable import Kollocol

struct VerifyCodeLogicTests {
    @Test
    func verifySuccessPassesRegistrationFlag() async {
        let presenter = VerifyCodePresenterSpy()
        let authService = VerifyCodeAuthServiceMock()
        await authService.setVerifyResult(true)
        let logic = VerifyCodeLogic(presenter: presenter, authService: authService)

        await logic.verify(code: "123456", with: "user@example.com")

        let requests = await authService.verifyRequests()
        #expect(requests.count == 1)
        #expect(requests.first?.0 == "123456")
        #expect(requests.first?.1 == "user@example.com")
        #expect(await presenter.successFlags() == [true])
        #expect(await presenter.verifyErrors().isEmpty)
    }

    @Test
    func verifyFailurePresentsError() async {
        let presenter = VerifyCodePresenterSpy()
        let authService = VerifyCodeAuthServiceMock()
        await authService.setVerifyError(.unauthorized)
        let logic = VerifyCodeLogic(presenter: presenter, authService: authService)

        await logic.verify(code: "123456", with: "user@example.com")

        let errors = await presenter.verifyErrors()
        #expect(errors.count == 1)
        #expect(isAuthServiceError(errors.first, .unauthorized))
        #expect(await presenter.successFlags().isEmpty)
    }

    @Test
    func resendCodeSuccessCallsService() async {
        let presenter = VerifyCodePresenterSpy()
        let authService = VerifyCodeAuthServiceMock()
        let logic = VerifyCodeLogic(presenter: presenter, authService: authService)

        await logic.resendCode(to: "user@example.com")

        #expect(await authService.resendRequests() == ["user@example.com"])
        #expect(await presenter.resendErrors().isEmpty)
    }

    @Test
    func resendCodeFailurePresentsError() async {
        let presenter = VerifyCodePresenterSpy()
        let authService = VerifyCodeAuthServiceMock()
        await authService.setResendError(.tooManyRequests)
        let logic = VerifyCodeLogic(presenter: presenter, authService: authService)

        await logic.resendCode(to: "user@example.com")

        let errors = await presenter.resendErrors()
        #expect(errors.count == 1)
        #expect(isAuthServiceError(errors.first, .tooManyRequests))
    }
}

private actor VerifyCodePresenterSpy: VerifyCodePresenter {
    private var successFlagsStorage: [Bool] = []
    private var verifyErrorsStorage: [AuthServiceError] = []
    private var resendErrorsStorage: [AuthServiceError] = []

    func presentSuccessfulVerifying(isRegistered: Bool) async {
        successFlagsStorage.append(isRegistered)
    }

    func presentVerifyingError(_ error: AuthServiceError) async {
        verifyErrorsStorage.append(error)
    }

    func presentResendCodeError(_ error: AuthServiceError) async {
        resendErrorsStorage.append(error)
    }

    func successFlags() -> [Bool] {
        successFlagsStorage
    }

    func verifyErrors() -> [AuthServiceError] {
        verifyErrorsStorage
    }

    func resendErrors() -> [AuthServiceError] {
        resendErrorsStorage
    }
}

private actor VerifyCodeAuthServiceMock: AuthService {
    private var verifyRequestsStorage: [(code: String, email: String)] = []
    private var resendRequestsStorage: [String] = []
    private var verifyResult = false
    private var verifyError: AuthServiceError?
    private var resendError: AuthServiceError?

    func setVerifyResult(_ value: Bool) {
        verifyResult = value
    }

    func setVerifyError(_ error: AuthServiceError?) {
        verifyError = error
    }

    func setResendError(_ error: AuthServiceError?) {
        resendError = error
    }

    func verifyRequests() -> [(String, String)] {
        verifyRequestsStorage.map { ($0.code, $0.email) }
    }

    func resendRequests() -> [String] {
        resendRequestsStorage
    }

    func login(using email: String) async throws {
    }

    func logout() async throws {
    }

    func refreshToken(with token: String) async throws {
    }

    func resendCode(to email: String) async throws {
        resendRequestsStorage.append(email)
        if let resendError {
            throw resendError
        }
    }

    func verify(code: String, with email: String) async throws -> Bool {
        verifyRequestsStorage.append((code, email))
        if let verifyError {
            throw verifyError
        }
        return verifyResult
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
