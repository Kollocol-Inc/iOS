//
//  AlertPresenting.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import UIKit

// MARK: - AlertPresenting
@MainActor
protocol AlertPresenting: AnyObject {
    func presentAlert(_ alert: UIAlertController)
}

// MARK: - Implementation
extension AlertPresenting {
    func showAlert(
        title: String,
        message: String,
        okTitle: String = "ОК"
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle, style: .default))
        presentAlert(alert)
    }

    func showConfirmationAlert(
        title: String,
        message: String,
        cancelTitle: String = "Отмена",
        confirmTitle: String,
        confirmStyle: UIAlertAction.Style = .destructive,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        presentAlert(alert)
    }
}
