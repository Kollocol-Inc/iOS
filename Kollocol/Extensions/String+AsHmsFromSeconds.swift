//
//  String+AsHmsFromSeconds.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import Foundation

extension String {
    /// Interprets string as seconds and returns localized short HMS format.
    func asHmsFromSeconds() -> String? {
        guard let totalSeconds = Int(self.trimmingCharacters(in: .whitespacesAndNewlines)),
              totalSeconds >= 0
        else { return nil }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours) \("timeHourShort".localized)")
        }

        if minutes > 0 || hours > 0 {
            if minutes > 0 {
                parts.append("\(minutes) \("timeMinuteShort".localized)")
            } else if hours > 0 && seconds > 0 {
                parts.append("0 \("timeMinuteShort".localized)")
            }
        }

        if seconds > 0 || parts.isEmpty {
            parts.append("\(seconds) \("timeSecondShort".localized)")
        }

        return parts.joined(separator: " ")
    }
}
