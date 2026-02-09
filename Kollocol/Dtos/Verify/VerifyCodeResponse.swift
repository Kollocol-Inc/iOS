//
//  VerifyCodeResponse.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

struct VerifyCodeResponse: Decodable {
    let accessToken: String
    let isRegistered: Bool
    let message: String
    let refreshToken: String
    let success: Bool
    let userId: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case isRegistered = "is_registered"
        case message = "message"
        case refreshToken = "refresh_token"
        case success = "success"
        case userId = "user_id"
    }
}
