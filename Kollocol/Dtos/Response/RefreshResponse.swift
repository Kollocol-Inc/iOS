//
//  RefreshDTO.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

struct RefreshResponse: Decodable {
    let accessToken: String
    let message: String
    let refreshToken: String
    let success: Bool
    
    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case message
        case refreshToken = "refresh_token"
        case success
    }
}
