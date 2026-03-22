//
//  Date+RFC3339.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import Foundation

extension Date {
    func asRFC3339String(includeFractionalSeconds: Bool = false) -> String {
        let formatter: ISO8601DateFormatter

        if includeFractionalSeconds {
            formatter = RFC3339DateFormatters.withFractionalSeconds
        } else {
            formatter = RFC3339DateFormatters.standard
        }

        return formatter.string(from: self)
    }
}

private enum RFC3339DateFormatters {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}
