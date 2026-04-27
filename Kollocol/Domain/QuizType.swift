//
//  QuizType.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

enum QuizType: String {
    case sync = "sync"
    case async = "async"
}

extension QuizType {
    var displayName: String {
        switch self {
        case .sync:
            return "quizTypeSync".localized
        case .async:
            return "quizTypeAsync".localized
        }
    }

    var infoDescription: String {
        switch self {
        case .sync:
            return "quizTypeSyncInfo".localized
        case .async:
            return "quizTypeAsyncInfo".localized
        }
    }
}
