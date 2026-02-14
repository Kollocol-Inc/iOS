//
//  RegistrationModels.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum RegistrationModels {
    struct AvatarUpload {
        let image: UIImage
        let data: Data
        let fileName: String
        let mimeType: String
    }

    enum AvatarImageProcessor {
        static func prepareForCropping(_ image: UIImage, maxSide: CGFloat = 2048) -> UIImage {
            let normalized = image.normalizedOrientation()
            return normalized.resizedKeepingAspectRatio(maxSide: maxSide)
        }

        static func processForUpload(
            _ image: UIImage,
            maxSide: CGFloat = 1024,
            jpegQuality: CGFloat = 0.82
        ) -> AvatarUpload {
            let normalized = image.normalizedOrientation()
            let resized = normalized.resizedKeepingAspectRatio(maxSide: maxSide)

            if let jpeg = resized.jpegData(compressionQuality: jpegQuality) {
                return AvatarUpload(
                    image: resized,
                    data: jpeg,
                    fileName: "avatar.jpg",
                    mimeType: "image/jpeg"
                )
            }

            let png = resized.pngData() ?? Data()
            return AvatarUpload(
                image: resized,
                data: png,
                fileName: "avatar.png",
                mimeType: "image/png"
            )
        }
    }
}

// MARK: - UIImage+NormalizedOrientation
private extension UIImage {
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resizedKeepingAspectRatio(maxSide: CGFloat) -> UIImage {
        let maxInputSide = max(size.width, size.height)
        guard maxInputSide > maxSide, maxInputSide > 0 else { return self }

        let scaleFactor = maxSide / maxInputSide
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
