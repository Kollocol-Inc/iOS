//
//  AnyEncodable.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

struct AnyEncodable: Encodable, Sendable {
    private let encodeImpl: @Sendable (Encoder) throws -> Void

    init<T: Encodable & Sendable>(_ value: T) {
        self.encodeImpl = { encoder in
            try value.encode(to: encoder)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        try encodeImpl(encoder)
    }
}
