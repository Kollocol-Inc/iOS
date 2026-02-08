//
//  String+IsValidEmail.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

extension String {

    var isValidEmail: Bool {
        // минимум: текст + @ + текст + . + текст
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#

        return range(of: pattern, options: .regularExpression) != nil
    }
}
