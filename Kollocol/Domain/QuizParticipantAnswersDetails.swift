//
//  QuizParticipantAnswersDetails.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct QuizParticipantAnswersDetails {
    let answers: [QuizParticipantAnswer]
    let instance: QuizInstance?
    let questions: [Question]
}
