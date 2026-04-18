//
//  QuizParticipantsOverviewModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import Foundation

enum QuizParticipantsOverviewModels {
    enum Mode {
        case asyncState
        case review
    }

    struct InitialData {
        let instanceId: String
        let quizTitle: String
        let quizStatus: QuizStatus?
        let mode: Mode
    }

    enum LeftStatusIcon {
        case pendingReview
        case reviewed
    }

    struct ParticipantRowData {
        let userId: String?
        let fullName: String
        let email: String?
        let avatarURL: String?
        let leftStatusIcon: LeftStatusIcon?
        let showsChevron: Bool
        let isDimmed: Bool
    }

    enum Row {
        case header(title: String)
        case headerWithCount(title: String, count: Int)
        case reviewHeader(title: String, totalCount: Int, reviewedCount: Int)
        case participant(ParticipantRowData)
        case empty(text: String)
    }
}
