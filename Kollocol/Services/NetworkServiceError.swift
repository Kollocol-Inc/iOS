//
//  NetworkServiceError.swift
//  Kollocol
//
//  Created by Codex on 05.03.2026.
//

import Foundation

protocol NetworkServiceError: Error {
    static var offline: Self { get }
    static var unknown: Self { get }
    static func mapStatusCode(_ code: Int) -> Self?
}

extension NetworkServiceError {
    static func wrap(_ error: Error) -> Self {
        if let serviceError = error as? Self {
            return serviceError
        }

        guard let networkError = error as? NetworkError else {
            return .unknown
        }

        switch networkError {
        case .transport(let urlError):
            return urlError.code == .notConnectedToInternet ? .offline : .unknown

        case .httpStatus(let code, _):
            return mapStatusCode(code) ?? .unknown

        default:
            return .unknown
        }
    }
}
