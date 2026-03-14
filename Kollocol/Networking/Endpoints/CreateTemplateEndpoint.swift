//
//  CreateTemplateEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 10.03.2026.
//

import Foundation

struct CreateTemplateEndpoint: Endpoint {
    typealias Response = EmptyResponse

    let description: String?
    let questions: [QuestionInputDto]?
    let quizType: QuizType?
    let settings: QuizSettingsDTO?
    let title: String?

    var method: HTTPMethod { .post }
    var path: String { "/quizzes/templates" }
    var body: AnyEncodable? {
        AnyEncodable(
            Body(
                description: description,
                questions: questions,
                quizType: quizType,
                settings: settings,
                title: title
            )
        )
    }
    var multipart: MultipartFormData? { nil }

    struct Body: Encodable {
        let description: String?
        let questions: [QuestionInputDto]?
        let quizType: QuizType?
        let settings: QuizSettingsDTO?
        let title: String?

        private enum CodingKeys: String, CodingKey {
            case description
            case questions
            case quizType = "quiz_type"
            case settings
            case title
        }
    }
}

// MARK: - Encodable
extension CreateTemplateEndpoint.Body {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(questions, forKey: .questions)
        try container.encodeEnumIfPresent(quizType, forKey: .quizType)
        try container.encodeIfPresent(settings, forKey: .settings)
        try container.encodeIfPresent(title, forKey: .title)
    }
}
