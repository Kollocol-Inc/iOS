//
//  GetInstanceResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import Foundation

struct GetInstanceResponse: Decodable {
    let instance: InstanceDTO?
    let questions: [QuestionDTO]?
}
