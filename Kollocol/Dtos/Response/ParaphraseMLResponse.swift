//
//  ParaphraseMLResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct ParaphraseMLResponse: Decodable {
    let text: String?
}

// MARK: - ParaphraseMLResponse -> ParaphrasedText
extension ParaphraseMLResponse {
    func toDomain() -> ParaphrasedText {
        ParaphrasedText(text: text)
    }
}
