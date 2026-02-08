//
//  NetworkError.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case transport(URLError)
    case invalidResponse
    case httpStatus(code: Int, data: Data)
    case decoding(Error)
}
