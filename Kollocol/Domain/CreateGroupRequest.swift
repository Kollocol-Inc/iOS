//
//  CreateGroupRequest.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct CreateGroupRequest {
    let avatarUrl: String?
    let description: String?
    let memberEmails: [String]?
    let name: String
}
