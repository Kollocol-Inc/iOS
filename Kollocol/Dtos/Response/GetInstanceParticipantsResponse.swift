//
//  GetInstanceParticipantsResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetInstanceParticipantsResponse: Decodable {
    let participants: [ParticipantDTO]
}
