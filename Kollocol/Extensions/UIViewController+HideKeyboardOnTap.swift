//
//  UIViewController+HideKeyboardOnTap.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit
import ObjectiveC

private final class BackgroundDismissControl: UIControl {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? self : nil
    }
}

private enum DismissKeyboardOverlayKey {
    static var key: UInt8 = 0
}

extension UIViewController {

    func enableKeyboardDismissOnBackgroundTap() {
        if objc_getAssociatedObject(self, &DismissKeyboardOverlayKey.key) as? UIControl != nil { return }

        let overlay = BackgroundDismissControl()
        overlay.addTarget(self, action: #selector(_dismissKeyboardOverlayTapped), for: .touchUpInside)

        view.insertSubview(overlay, at: 0)

        overlay.pin(to: view)

        objc_setAssociatedObject(self, &DismissKeyboardOverlayKey.key, overlay, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func disableKeyboardDismissOnBackgroundTap() {
        (objc_getAssociatedObject(self, &DismissKeyboardOverlayKey.key) as? UIControl)?.removeFromSuperview()
        objc_setAssociatedObject(self, &DismissKeyboardOverlayKey.key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc private func _dismissKeyboardOverlayTapped() {
        view.endEditing(true)
    }
}


