//
//  GradeAnswerRequest.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GradeAnswerRequest {
    let participantId: String
    let questionId: String
    let score: Int?
}
