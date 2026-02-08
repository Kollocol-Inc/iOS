//
//  UITextField+SetFocused.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

extension UITextField {
    func setFocusedBorder(isActive: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.layer.borderWidth = isActive ? 1.5 : 0
            self.layer.borderColor = isActive ? UIColor.accentPrimary.cgColor : nil
        }
    }
}
