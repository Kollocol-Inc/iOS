//
//  MultipartFormData.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.02.2026.
//

import Foundation

struct MultipartFormData: Sendable {
    // MARK: - Typealias
    typealias Boundary = String

    // MARK: - Constants
    private enum Constants {
        static let lineBreak = "\r\n"
    }

    // MARK: - Properties
    let boundary: Boundary
    let parts: [Part]

    var contentTypeHeaderValue: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    // MARK: - Lifecycle
    init(boundary: Boundary = UUID().uuidString, parts: [Part]) {
        self.boundary = boundary
        self.parts = parts
    }

    // MARK: - Methods
    func encode() -> Data {
        var data = Data()

        for part in parts {
            data.appendString("--\(boundary)\(Constants.lineBreak)")

            if let fileName = part.fileName, let mimeType = part.mimeType {
                // файл
                data.appendString(
                    "Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(fileName)\"\(Constants.lineBreak)"
                )
                data.appendString("Content-Type: \(mimeType)\(Constants.lineBreak)\(Constants.lineBreak)")
                data.append(part.data)
                data.appendString(Constants.lineBreak)
            } else {
                // текст
                data.appendString("Content-Disposition: form-data; name=\"\(part.name)\"\(Constants.lineBreak)\(Constants.lineBreak)")
                data.append(part.data)
                data.appendString(Constants.lineBreak)
            }
        }

        data.appendString("--\(boundary)--\(Constants.lineBreak)")
        return data
    }
}

// MARK: - MultipartFormData.Part
extension MultipartFormData {
    struct Part: Sendable {
        let name: String
        let data: Data
        let fileName: String?
        let mimeType: String?

        init(name: String, data: Data) {
            self.name = name
            self.data = data
            self.fileName = nil
            self.mimeType = nil
        }

        init(name: String, fileName: String, mimeType: String, data: Data) {
            self.name = name
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}

// MARK: - Data
private extension Data {
    mutating func appendString(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        append(data)
    }
}

