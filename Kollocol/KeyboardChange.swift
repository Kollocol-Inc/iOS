//
//  KeyboardChange.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

struct KeyboardChange {
    let duration: Double
    let options: UIView.AnimationOptions
    let endFrame: CGRect

    init?(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
            let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        else { return nil }

        self.duration = duration
        self.options = UIView.AnimationOptions(rawValue: curve << 16)
        self.endFrame = frame.cgRectValue
    }
}
