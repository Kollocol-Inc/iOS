//
//  KeyedDecodingContainer+decodeStringFromStringOrIntIfPresent.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 23.03.2026.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeStringFromStringOrIntIfPresent(forKey key: Key) throws -> String? {
        guard contains(key) else { return nil }
        if try decodeNil(forKey: key) { return nil }

        if let stringValue = try? decode(String.self, forKey: key) {
            return stringValue
        }

        if let intValue = try? decode(Int.self, forKey: key) {
            return String(intValue)
        }

        throw DecodingError.typeMismatch(
            String.self,
            .init(
                codingPath: codingPath + [key],
                debugDescription: "Expected String or Int for key '\(key.stringValue)'"
            )
        )
    }
}
