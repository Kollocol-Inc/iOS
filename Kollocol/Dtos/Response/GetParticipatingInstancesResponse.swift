//
//  GetParticipatingInstancesResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct GetParticipatingInstancesResponse: Decodable {
    let instances: [ParticipatingInstanceDTO]

    private enum CodingKeys: String, CodingKey {
        case instances
    }
}
