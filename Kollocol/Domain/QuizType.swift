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
        case .sync:  return "Синхронный"
        case .async: return "Асинхронный"
        }
    }

    var infoDescription: String {
        switch self {
        case .sync:
            return "Все участники проходят квиз одновременно под контролем создателя"
        case .async:
            return "Участники могут проходить квиз в любое время до дедлайна"
        }
    }
}
