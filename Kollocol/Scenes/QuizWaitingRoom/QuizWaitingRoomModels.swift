//
//  QuizWaitingRoomModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import Foundation

enum QuizWaitingRoomModels {
    struct InitialData {
        let accessCode: String
    }

    enum Row {
        case participantsHeader(count: Int)
        case participant(QuizParticipant?)
    }
}
