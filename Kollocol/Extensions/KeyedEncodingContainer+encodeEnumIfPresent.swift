//
//  KeyedEncodingContainer+encodeEnumIfPresent.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import Foundation

extension KeyedEncodingContainer {
    mutating func encodeEnumIfPresent<T>(_ value: T?, forKey key: Key) throws
    where T: RawRepresentable, T.RawValue == String {
        try encodeIfPresent(value?.rawValue, forKey: key)
    }
}
