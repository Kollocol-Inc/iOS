//
//  String+AsHmsFromSeconds.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import Foundation

extension String {
    /// Интерпретирует строку как секунды и возвращает "ч./м./с." формат.
    /// Примеры:
    /// "180" -> "3 м."
    /// "200" -> "3 м. 20 с."
    /// "45"  -> "45 с."
    /// "10000" -> "2 ч. 46 м. 40 с."
    func asHmsFromSeconds() -> String? {
        guard let totalSeconds = Int(self.trimmingCharacters(in: .whitespacesAndNewlines)),
              totalSeconds >= 0
        else { return nil }

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours) ч.")
        }

        if minutes > 0 || hours > 0 {
            if minutes > 0 {
                parts.append("\(minutes) м.")
            } else if hours > 0 && seconds > 0 {
                parts.append("0 м.")
            }
        }

        if seconds > 0 || parts.isEmpty {
            parts.append("\(seconds) с.")
        }

        return parts.joined(separator: " ")
    }
}
