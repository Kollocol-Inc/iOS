//
//  ErrorResponse.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

struct ErrorResponse: Decodable {
    let error: String
    let message: String
}
