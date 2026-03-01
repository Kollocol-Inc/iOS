//
//  VerifyCodeResponse.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

struct VerifyCodeResponse: Decodable {
    let accessToken: String
    let isRegistered: Bool
    let refreshToken: String
    let userId: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case isRegistered = "is_registered"
        case refreshToken = "refresh_token"
        case userId = "user_id"
    }
}
