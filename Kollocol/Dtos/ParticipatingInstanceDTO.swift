//
//  ParticipatingInstanceDTO.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import Foundation

struct ParticipatingInstanceDTO: Decodable {
    let instance:       InstanceDTO?
    let sessionStatus:  SessionStatus?

    private enum CodingKeys: String, CodingKey {
        case instance
        case sessionStatus = "session_status"
    }
}

// MARK: - ParticipatingInstanceDTO -> ParticipatingInstance
extension ParticipatingInstanceDTO {
    func toDomain() -> ParticipatingInstance {
        return ParticipatingInstance(
            instance: self.instance?.toDomain(),
            sessionStatus: self.sessionStatus
        )
    }
}

// MARK: - Decodable
extension ParticipatingInstanceDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        instance = try container.decodeIfPresent(InstanceDTO.self, forKey: .instance)
        sessionStatus = try container.decodeEnumIfPresent(SessionStatus.self, forKey: .sessionStatus)
    }
}
