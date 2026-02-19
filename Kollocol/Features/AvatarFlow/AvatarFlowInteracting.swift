//
//  AvatarFlowInteracting.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.02.2026.
//

import UIKit

@MainActor
protocol AvatarFlowInteracting: AnyObject {
    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async
    func presentAvatarDeleteConfirmation(onConfirm: @escaping @MainActor () -> Void) async
}
