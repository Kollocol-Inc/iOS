//
//  ParaphraseMLRequestDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import Foundation

struct ParaphraseMLRequestDTO: Encodable {
    let text: String
}

// MARK: - ParaphraseMLRequest -> ParaphraseMLRequestDTO
extension ParaphraseMLRequest {
    func toDto() -> ParaphraseMLRequestDTO {
        ParaphraseMLRequestDTO(text: text)
    }
}
