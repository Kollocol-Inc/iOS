//
//  VerifyCodeResponse.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

struct VerifyCodeRequest: Encodable {
    let code: String
    let email: String
}
