//
//  MLServiceImplTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct MLServiceImplTests {
    @Test
    func generateTemplateSuccessSendsRequestAndMapsDomain() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "title": "Biology Quiz",
              "questions": [
                {
                  "correct_answer": "Mitochondria",
                  "max_score": 5,
                  "options": [],
                  "text": "Powerhouse of the cell?",
                  "time_limit_sec": 20,
                  "type": "open"
                }
              ]
            }
            """#
        )

        let service = MLServiceImpl(api: context.makeAPIClient())
        let template = try await service.generateTemplate(
            GenerateTemplateMLRequest(text: "Make a short biology template")
        )

        #expect(template.title == "Biology Quiz")
        #expect(template.questions.count == 1)
        #expect(template.questions.first?.text == "Powerhouse of the cell?")
        #expect(template.questions.first?.type == .openEnded)

        if case .openText(let answer)? = template.questions.first?.correctAnswer {
            #expect(answer == "Mitochondria")
        } else {
            Issue.record("Expected openText correct answer")
        }

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/ml/generate/template")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["text"] == "Make a short biology template")
    }

    @Test
    func generateTemplateQuestionsSuccessSendsPayloadAndMapsDomain() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "questions": [
                {
                  "correct_answer": 1,
                  "max_score": 3,
                  "options": ["A", "B", "C"],
                  "text": "Choose B",
                  "time_limit_sec": 10,
                  "type": "single"
                }
              ]
            }
            """#
        )

        let sourceQuestion = Question(
            correctAnswer: .singleChoice(1),
            id: nil,
            maxScore: 3,
            options: ["A", "B", "C"],
            text: "Source question",
            timeLimitSec: 10,
            type: .singleChoice
        )

        let service = MLServiceImpl(api: context.makeAPIClient())
        let generated = try await service.generateTemplateQuestions(
            GenerateTemplateQuestionsMLRequest(
                text: "Generate additional questions",
                questions: [sourceQuestion]
            )
        )

        #expect(generated.questions.count == 1)
        #expect(generated.questions.first?.text == "Choose B")
        #expect(generated.questions.first?.type == .singleChoice)

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/ml/generate/template/questions")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: Any])
        #expect(body["text"] as? String == "Generate additional questions")

        let questions = try #require(body["questions"] as? [[String: Any]])
        let firstQuestion = try #require(questions.first)
        #expect(firstQuestion["type"] as? String == "single")
        #expect(firstQuestion["correct_answer"] as? Int == 1)
        #expect((firstQuestion["options"] as? [String])?.count == 3)
    }

    @Test
    func paraphraseSuccessSendsRequestAndMapsDomain() async throws {
        let context = makeNetworkTestContext()
        context.enqueueJSON(
            statusCode: 200,
            json: #"""
            {
              "text": "Paraphrased output text"
            }
            """#
        )

        let service = MLServiceImpl(api: context.makeAPIClient())
        let result = try await service.paraphrase(
            ParaphraseMLRequest(text: "Original text")
        )

        #expect(result.text == "Paraphrased output text")

        let request = try #require(context.recordedRequests().first)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.path == "/ml/paraphrase")

        let bodyData = try #require(extractBodyData(from: request))
        let body = try #require(try JSONSerialization.jsonObject(with: bodyData) as? [String: String])
        #expect(body["text"] == "Original text")
    }

    @Test
    func generateTemplateMaps429ToTooManyRequests() async {
        let context = makeNetworkTestContext()
        context.enqueueJSON(statusCode: 429, json: #"{"error":"rate_limited"}"#)

        let service = MLServiceImpl(api: context.makeAPIClient())

        do {
            _ = try await service.generateTemplate(GenerateTemplateMLRequest(text: "Rate limited"))
            Issue.record("Expected MLServiceError.tooManyRequests")
        } catch let error as MLServiceError {
            #expect(isMLServiceError(error, .tooManyRequests))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func paraphraseMapsOfflineTransportError() async {
        let context = makeNetworkTestContext()
        context.enqueue(error: URLError(.notConnectedToInternet))

        let service = MLServiceImpl(api: context.makeAPIClient())

        do {
            _ = try await service.paraphrase(ParaphraseMLRequest(text: "Offline case"))
            Issue.record("Expected MLServiceError.offline")
        } catch let error as MLServiceError {
            #expect(isMLServiceError(error, .offline))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

private func isMLServiceError(_ actual: MLServiceError, _ expected: MLServiceError) -> Bool {
    switch (actual, expected) {
    case (.badRequest, .badRequest),
            (.unauthorized, .unauthorized),
            (.tooManyRequests, .tooManyRequests),
            (.server, .server),
            (.offline, .offline),
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
