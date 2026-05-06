//
//  GroupWithMembers.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GroupWithMembers {
    let avatarUrl: String?
    let createdAt: Date?
    let description: String?
    let id: String?
    let invitedUsers: [GroupMember]
    let memberCount: Int?
    let members: [GroupMember]
    let name: String?
    let ownerId: String?
    let pendingInvitesCount: Int?
    let updatedAt: Date?
}
