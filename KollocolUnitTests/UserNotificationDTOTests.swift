//
//  UserNotificationDTOTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import Foundation
import Testing
@testable import Kollocol

struct UserNotificationDTOTests {
    @Test
    func decodesGroupIdFromSnakeCaseField() throws {
        let json = """
        {
          "id": "notification-id-1",
          "type": "group_invite",
          "group_id": "group-id-1"
        }
        """

        let dto = try decode(from: json)

        #expect(dto.groupId == "group-id-1")
    }

    @Test
    func decodesGroupIdFromAlternateFieldsAndFallsBackToUUIDInContent() throws {
        let jsonWithEntityId = """
        {
          "id": "notification-id-2",
          "type": "group_invite",
          "entity_id": "group-id-2"
        }
        """
        let dtoWithEntityId = try decode(from: jsonWithEntityId)
        #expect(dtoWithEntityId.groupId == "group-id-2")

        let jsonWithUUIDInContent = """
        {
          "id": "notification-id-3",
          "type": "group_invite",
          "content": "Invite to group 550e8400-e29b-41d4-a716-446655440000"
        }
        """
        let dtoWithUUIDInContent = try decode(from: jsonWithUUIDInContent)
        #expect(dtoWithUUIDInContent.groupId == "550e8400-e29b-41d4-a716-446655440000")
    }
}

private extension UserNotificationDTOTests {
    func decode(from json: String) throws -> UserNotificationDTO {
        try JSONDecoder().decode(UserNotificationDTO.self, from: Data(json.utf8))
    }
}
