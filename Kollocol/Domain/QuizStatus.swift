//
//  QuizStatus.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

enum QuizStatus: String {
    case waiting = "waiting"
    case active = "active"
    case pendingReview = "pending_review"
    case reviewed = "reviewed"
    case publishedResults = "published_results"
}
