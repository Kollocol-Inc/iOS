//
//  GroupAvatarUploadResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct GroupAvatarUploadResponse: Decodable {
    let avatarUrl: String?

    private enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
    }
}
