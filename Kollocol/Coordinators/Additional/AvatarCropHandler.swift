//
//  AvatarCropHandler.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.02.2026.
//

import Mantis
import UIKit

// MARK: - AvatarCropHandler
@MainActor
final class AvatarCropHandler: NSObject, CropViewControllerDelegate {
    // MARK: - Typealias
    typealias OnFinish = @MainActor (UIImage?) -> Void

    // MARK: - Properties
    private let onFinish: OnFinish

    // MARK: - Lifecycle
    init(onFinish: @escaping OnFinish) {
        self.onFinish = onFinish
        super.init()
    }

    // MARK: - Methods
    func cropViewControllerDidCrop(
        _ cropViewController: CropViewController,
        cropped: UIImage,
        transformation: Transformation,
        cropInfo: CropInfo
    ) {
        cropViewController.dismiss(animated: true) { [onFinish] in
            onFinish(cropped)
        }
    }

    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true) { [onFinish] in
            onFinish(nil)
        }
    }

    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage) {
        cropViewController.dismiss(animated: true) { [onFinish] in
            onFinish(nil)
        }
    }
}

