//
//  QuizServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct QuizServiceImplTests {
    @Test
    func createQuizInstanceReturnsTrimmedAccessCodeAndUsesEndpoint() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "access_code": "  CODE-1  ",
              "instance_id": "instance-1"
            }
            """#
        )

        let service = QuizServiceImpl(api: context.makeAPIClient())
        let request = CreateInstanceRequest(
            deadline: Date(timeIntervalSince1970: 1_712_000_000),
            groupId: "group-1",
            templateId: "template-1",
            title: "Quiz title"
        )

        let accessCode = try await service.createQuizInstance(request)

        #expect(accessCode == "CODE-1")

        let recordedRequest = try #require(context.recordedRequests().first)
        #expect(recordedRequest.httpMethod == "POST")
        #expect(recordedRequest.url?.path == "/quizzes/instances")

        let bodyData = try #require(extractBodyData(from: recordedRequest))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(body["group_id"] as? String == "group-1")
        #expect(body["template_id"] as? String == "template-1")
        #expect(body["title"] as? String == "Quiz title")
        #expect(body["deadline"] as? String != nil)
    }

    @Test
    func createQuizInstanceReturnsNilWhenAccessCodeIsBlank() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "access_code": "   ",
              "instance_id": "instance-2"
            }
            """#
        )

        let service = QuizServiceImpl(api: context.makeAPIClient())
        let accessCode = try await service.createQuizInstance(
            CreateInstanceRequest(deadline: nil, groupId: nil, templateId: "template-2", title: nil)
        )

        #expect(accessCode == nil)
    }

    @Test
    func createQuizInstanceMaps429ToTooManyRequests() async {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 429, json: #"{"error":"rate_limited"}"#)

        let service = QuizServiceImpl(api: context.makeAPIClient())

        do {
            _ = try await service.createQuizInstance(
                CreateInstanceRequest(deadline: nil, groupId: nil, templateId: "template-3", title: nil)
            )
            Issue.record("Expected QuizServiceError.tooManyRequests")
        } catch let error as QuizServiceError {
            #expect(isQuizServiceError(error, .tooManyRequests))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func getParticipatingQuizzesUsesSessionStatusQueryAndMapsDomain() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeParticipatingInstancesJSON())

        let service = QuizServiceImpl(api: context.makeAPIClient())
        let instances = try await service.getParticipatingQuizzes(sessionStatus: .inProgress)

        #expect(instances.count == 1)
        #expect(instances.first?.sessionStatus == .joined)
        #expect(instances.first?.instance?.id == "instance-10")
        #expect(instances.first?.instance?.quizType == .sync)
        #expect(instances.first?.instance?.totalQuestions == "10")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/quizzes/instances/participating")
        #expect(request.url?.query == "session_status=in_progress")
    }

    @Test
    func getHostingQuizzesUsesStatusQueryAndMapsDomain() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 200, json: makeHostingInstancesJSON())

        let service = QuizServiceImpl(api: context.makeAPIClient())
        let instances = try await service.getHostingQuizzes(status: .active)

        #expect(instances.count == 1)
        #expect(instances.first?.id == "instance-20")
        #expect(instances.first?.quizType == .async)
        #expect(instances.first?.status == .active)
        #expect(instances.first?.totalTime == "300")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/quizzes/instances/hosting")
        #expect(request.url?.query == "status=active")
    }
}

private func makeParticipatingInstancesJSON() -> String {
    #"""
    {
      "instances": [
        {
          "session_status": "joined",
          "instance": {
            "id": "instance-10",
            "access_code": "AC-10",
            "created_at": "2026-04-01T10:00:00Z",
            "deadline": null,
            "group_id": "group-10",
            "host_user_id": "host-10",
            "quiz_type": "sync",
            "settings": {
              "allow_review": true,
              "random_order": false,
              "show_correct_answer": true,
              "time_limit_total": false
            },
            "status": "active",
            "template_id": "template-10",
            "title": "Participating quiz",
            "total_questions": 10,
            "total_time": 120
          }
        }
      ]
    }
    """#
}

private func makeHostingInstancesJSON() -> String {
    #"""
    {
      "instances": [
        {
          "id": "instance-20",
          "access_code": "AC-20",
          "created_at": "2026-04-01T10:00:00Z",
          "deadline": null,
          "group_id": "group-20",
          "host_user_id": "host-20",
          "quiz_type": "async",
          "settings": {
            "allow_review": true,
            "random_order": true,
            "show_correct_answer": true,
            "time_limit_total": false
          },
          "status": "active",
          "template_id": "template-20",
          "title": "Hosting quiz",
          "total_questions": "15",
          "total_time": "300"
        }
      ]
    }
    """#
}

private func isQuizServiceError(_ actual: QuizServiceError, _ expected: QuizServiceError) -> Bool {
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
