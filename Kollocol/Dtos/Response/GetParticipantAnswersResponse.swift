//
//  GetParticipantAnswersResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetParticipantAnswersResponse: Decodable {
    let answers: [UserAnswerDTO]?
    let instance: InstanceDTO?
    let questions: [QuestionDTO]?
}
