//
//  UserServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct UserServiceImplTests {
    @Test
    func getUserProfileSuccessReturnsDTOAndUsesEndpoint() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeUserJSON(id: "user-1"))

        let service = makeUserService(context: context)

        let user = try await service.getUserProfile()

        #expect(user.id == "user-1")
        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/users/me")
    }

    @Test
    func getUserProfileMaps401ToUnauthorizedError() async {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 401, json: #"{"error":"unauthorized"}"#)

        let service = makeUserService(context: context)

        do {
            _ = try await service.getUserProfile()
            Issue.record("Expected UserServiceError.unauthorized")
        } catch let error as UserServiceError {
            #expect(isUserServiceError(error, .unauthorized))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func updateUserProfileSendsPayloadAndReturnsDTO() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeUserJSON(id: "user-2", firstName: "Alice", lastName: "Smith"))

        let service = makeUserService(context: context)
        let user = try await service.updateUserProfile(name: "Alice", surname: "Smith")

        #expect(user.firstName == "Alice")
        #expect(user.lastName == "Smith")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path == "/users/me")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["first_name"] == "Alice")
        #expect(body["last_name"] == "Smith")
    }

    @Test
    func uploadAvatarUsesMultipartRequest() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeUserJSON(id: "user-3"))

        let service = makeUserService(context: context)
        try await service.uploadAvatar(data: Data([0x41, 0x42, 0x43]))

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/users/me/avatar/upload")

        let contentType = request.value(forHTTPHeaderField: "Content-Type") ?? ""
        #expect(contentType.contains("multipart/form-data"))
        let bodyData = try #require(extractBodyData(from: request))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? ""
        #expect(bodyString.contains("name=\"avatar\""))
        #expect(bodyString.contains("filename=\"avatar.jpg\""))
        #expect(bodyString.contains("Content-Type: image/jpeg"))
    }

    @Test
    func updateNotificationsSendsPayloadAndReturnsDTO() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "deadline_reminder": "daily",
              "group_invites": true,
              "new_quizzes": false,
              "quiz_results": true,
              "user_id": "user-4"
            }
            """#
        )

        let service = makeUserService(context: context)
        let settings = try await service.updateNotifications(
            deadlineReminder: "daily",
            groupInvites: true,
            newQuizzes: false,
            quizResults: true
        )

        #expect(settings.deadlineReminder == "daily")
        #expect(settings.groupInvites == true)
        #expect(settings.newQuizzes == false)
        #expect(settings.quizResults == true)
        #expect(settings.userId == "user-4")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "PUT")
        #expect(request.url?.path == "/users/me/notifications")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(body["deadline_reminder"] as? String == "daily")
        #expect(body["group_invites"] as? Bool == true)
        #expect(body["new_quizzes"] as? Bool == false)
        #expect(body["quiz_results"] as? Bool == true)
    }

    @Test
    func registerSuccessSetsIsRegisteredFlag() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeUserJSON(id: "user-5", firstName: "Bob", lastName: "Taylor"))

        let udService = UserServiceUserDefaultsMock()
        let service = makeUserService(context: context, udService: udService)

        try await service.register(name: "Bob", surname: "Taylor")

        #expect(udService.isRegistered)
        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/users/register")
    }

    @Test
    func deleteAvatarUsesDeleteEndpoint() async throws {
        let context = makeNetworkTestContext()
        context.enqueue(statusCode: 200, data: Data())

        let service = makeUserService(context: context)
        try await service.deleteAvatar()

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "DELETE")
        #expect(request.url?.path == "/users/me/avatar/delete")
    }
}

private actor UserServiceTokenStoreMock: TokenStoring {
    func accessToken() async -> String? { nil }
    func refreshToken() async -> String? { nil }
    func set(_ pair: TokenPair) async {}
    func clear() async {}
}

private final class UserServiceUserDefaultsMock: UserDefaultsService {
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

private func makeUserService(
    context: NetworkTestContext,
    udService: UserServiceUserDefaultsMock = UserServiceUserDefaultsMock()
) -> UserServiceImpl {
    UserServiceImpl(
        api: context.makeAPIClient(),
        tokenStore: UserServiceTokenStoreMock(),
        udService: udService
    )
}

private func makeUserJSON(
    id: String,
    firstName: String = "John",
    lastName: String = "Doe",
    email: String = "john@example.com"
) -> String {
    #"""
    {
      "id": "\#(id)",
      "email": "\#(email)",
      "first_name": "\#(firstName)",
      "last_name": "\#(lastName)",
      "avatar_url": null,
      "created_at": "2026-04-01T10:00:00Z",
      "updated_at": "2026-04-02T10:00:00Z"
    }
    """#
}

private func isUserServiceError(_ actual: UserServiceError, _ expected: UserServiceError) -> Bool {
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

private func extractBodyData(from request: URLRequest) -> Data? {
    if let body = request.httpBody {
        return body
    }

    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    let bufferSize = 1_024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }

    var data = Data()
    while stream.hasBytesAvailable {
        let count = stream.read(buffer, maxLength: bufferSize)
        if count < 0 {
            return nil
        }
        if count == 0 {
            break
        }
        data.append(buffer, count: count)
    }

    return data
}
