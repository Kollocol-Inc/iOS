//
//  UploadAvatar.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.02.2026.
//

import Foundation

struct UploadAvatar: Endpoint {
    typealias Response = UserDTO

    let avatar: AvatarFile

    var method: HTTPMethod { .post }
    var path: String { "/users/me/avatar" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? {
        MultipartFormData(parts: [
            .init(name: "avatar", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data)
        ])
    }
}

extension UploadAvatar {
    struct AvatarFile: Sendable {
        let data: Data
        let fileName: String
        let mimeType: String

        init(data: Data, fileName: String = "avatar.jpg", mimeType: String = "image/jpeg") {
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}
