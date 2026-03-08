//
//  GetTemplatesResponse.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import Foundation

struct GetTemplatesResponse: Decodable {
    let templates: [TemplateDTO]
}
