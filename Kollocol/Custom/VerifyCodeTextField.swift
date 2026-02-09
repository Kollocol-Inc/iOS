//
//  VerifyCodeTextField.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

final class VerifyCodeTextField: StripedLoadingTextField {
    // MARK: - Properties
    var onBackspaceOnEmpty: ((VerifyCodeTextField) -> Void)?
    var onBackspaceAtBeginningWithText: ((VerifyCodeTextField) -> Void)?

    // MARK: - Methods
    override func deleteBackward() {
        let hasText = !(text ?? "").isEmpty

        if !hasText {
            onBackspaceOnEmpty?(self)
            return
        }

        if isCursorAtBeginning {
            onBackspaceAtBeginningWithText?(self)
            return
        }

        super.deleteBackward()
        sendActions(for: .editingChanged)
    }

    // MARK: - Private Methods
    private var isCursorAtBeginning: Bool {
        guard let range = selectedTextRange else { return false }
        return range.start == beginningOfDocument
    }
}
