//
//  MainModels.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum MainModels {
    enum Row {
        case header(title: String)
        case cards(items: [QuizInstanceViewData])
        case divider
    }
}
