//
//  CreateQuizInstanceResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 30.03.2026.
//

import Foundation

struct CreateQuizInstanceResponse: Decodable {
    let accessCode: String?
    let instanceId: String?

    private enum CodingKeys: String, CodingKey {
        case accessCode = "access_code"
        case instanceId = "instance_id"
    }
}
