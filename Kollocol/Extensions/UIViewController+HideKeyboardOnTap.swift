//
//  UIViewController+HideKeyboardOnTap.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit
import ObjectiveC

private final class KeyboardDismissTapHandler: NSObject, UIGestureRecognizerDelegate {
    // MARK: - Properties
    private weak var view: UIView?
    private let ignoresControls: Bool

    // MARK: - Lifecycle
    init(view: UIView, ignoresControls: Bool) {
        self.view = view
        self.ignoresControls = ignoresControls
        super.init()
    }

    // MARK: - Methods
    @objc func handleTap() {
        view?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard ignoresControls else { return true }
        return !isInsideUIControl(touch.view)
    }

    // MARK: - Private Methods
    private func isInsideUIControl(_ view: UIView?) -> Bool {
        var current = view
        while let v = current {
            if v is UIControl { return true }
            current = v.superview
        }
        return false
    }
}

private enum KeyboardDismissTapAssociatedKeys {
    static var gestureKey: UInt8 = 0
    static var handlerKey: UInt8 = 0
}

extension UIViewController {
    // MARK: - Methods
    func enableKeyboardDismissOnBackgroundTap(ignoresControls: Bool = true) {
        if objc_getAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.gestureKey) as? UITapGestureRecognizer != nil { return }

        let handler = KeyboardDismissTapHandler(view: view, ignoresControls: ignoresControls)
        let tap = UITapGestureRecognizer(target: handler, action: #selector(KeyboardDismissTapHandler.handleTap))
        tap.cancelsTouchesInView = false
        tap.delegate = handler

        view.addGestureRecognizer(tap)

        objc_setAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.handlerKey, handler, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.gestureKey, tap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func disableKeyboardDismissOnBackgroundTap() {
        if let tap = objc_getAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.gestureKey) as? UITapGestureRecognizer {
            view.removeGestureRecognizer(tap)
        }

        objc_setAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.gestureKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &KeyboardDismissTapAssociatedKeys.handlerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}


