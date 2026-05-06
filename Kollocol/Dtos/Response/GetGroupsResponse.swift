//
//  GetGroupsResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

struct GetGroupsResponse: Decodable {
    let groups: [GroupDTO]
}

