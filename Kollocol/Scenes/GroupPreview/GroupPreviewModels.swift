//
//  GroupPreviewModels.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import Foundation

enum GroupPreviewModels {
    struct InitialData {
        let groupId: String
        let title: String
        let subtitle: String?
        let avatarUrl: String?
        let ownerId: String?
        let isCurrentUserOwner: Bool
    }

    struct ViewData {
        let groupId: String
        let title: String
        let subtitle: String?
        let avatarUrl: String?
        let ownerId: String?
        let isCurrentUserOwner: Bool
    }

    struct ParticipantsViewData {
        let members: [ParticipantViewData]
        let invitedMembers: [ParticipantViewData]
    }

    struct ParticipantViewData {
        let id: String
        let email: String?
        let fullName: String
        let avatarUrl: String?
        let isInvited: Bool
        let rightAccessory: RightAccessory
    }

    enum RightAccessory {
        case none
        case crown
        case you
        case kick
        case removeInvite
    }

    struct EditGroupRequest {
        let name: String
        let description: String?
        let avatarAction: AvatarAction
    }

    enum AvatarAction {
        case unchanged
        case update(data: Data)
        case remove
    }
}
