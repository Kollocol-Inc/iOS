//
//  GetHostingInstancesResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 03.03.2026.
//

import Foundation

struct GetHostingInstancesResponse: Decodable {
    let instances: [InstanceDTO]

    private enum CodingKeys: String, CodingKey {
        case instances
    }
}
