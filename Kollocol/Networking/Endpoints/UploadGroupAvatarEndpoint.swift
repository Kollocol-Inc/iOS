//
//  UploadGroupAvatarEndpoint.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.05.2026.
//

import Foundation

struct UploadGroupAvatarEndpoint: Endpoint {
    typealias Response = GroupAvatarUploadResponse

    let avatar: AvatarFile

    var method: HTTPMethod { .post }
    var path: String { "/groups/avatar/upload" }
    var body: AnyEncodable? { nil }
    var multipart: MultipartFormData? {
        MultipartFormData(parts: [
            .init(name: "avatar", fileName: avatar.fileName, mimeType: avatar.mimeType, data: avatar.data)
        ])
    }
}

extension UploadGroupAvatarEndpoint {
    struct AvatarFile: Sendable {
        let data: Data
        let fileName: String
        let mimeType: String

        init(data: Data, fileName: String = "group-avatar.jpg", mimeType: String = "image/jpeg") {
            self.data = data
            self.fileName = fileName
            self.mimeType = mimeType
        }
    }
}
