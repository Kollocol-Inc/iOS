//
//  KeyedDecodingContainer+decodeEnumIfPresent.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

extension KeyedDecodingContainer {
    func decodeEnumIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T?
    where T: RawRepresentable, T.RawValue == String {
        let raw = try decodeIfPresent(String.self, forKey: key)
        return raw.flatMap(T.init(rawValue:))
    }
}
