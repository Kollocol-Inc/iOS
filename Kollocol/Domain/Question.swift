//
//  Question.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

enum QuestionCorrectAnswer {
    case openText(String)
    case singleChoice(Int)
    case multipleChoice([Int])
}

struct Question {
    let aiAnswer: String?
    let correctAnswer: QuestionCorrectAnswer?
    let id: String?
    let maxScore: Int?
    let options: [String]?
    let orderIndex: Int?
    let text: String?
    let timeLimitSec: Int?
    let type: QuestionType?
}

// MARK: - Question -> QuestionInputDTO
extension Question {
    func toDto() -> QuestionInputDto {
        let mappedCorrectAnswers: [String]? = {
            guard let correctAnswer else { return nil }

            switch correctAnswer {
            case .openText(let value):
                return [value]

            case .singleChoice(let index):
                if let options, options.indices.contains(index) {
                    let option = options[index]
                    return [option]
                }

                return ["\(index)"]

            case .multipleChoice(let indexes):
                guard indexes.isEmpty == false else { return [] }

                let resolved = indexes.map { index in
                    if let options, options.indices.contains(index) {
                        return options[index]
                    }

                    return "\(index)"
                }
                return resolved
            }
        }()

        return QuestionInputDto(
            correctAnswers: mappedCorrectAnswers,
            id: self.id,
            maxScore: self.maxScore,
            options: self.options,
            orderIndex: self.orderIndex,
            text: self.text,
            timeLimitSec: self.timeLimitSec,
            type: self.type
        )
    }
}
