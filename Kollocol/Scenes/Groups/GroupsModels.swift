//
//  MainModels.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import Foundation

enum GroupsModels {
    enum Mode {
        case member
        case owner
    }

    struct GroupViewData: Equatable {
        let id: String?
        let title: String
        let subtitle: String?
        let ownerId: String?
        let memberCount: Int
        let pendingInvitesCount: Int
        let avatarUrl: String?
    }
}
