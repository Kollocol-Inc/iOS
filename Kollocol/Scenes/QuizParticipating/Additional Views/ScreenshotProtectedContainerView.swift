//
//  ScreenshotProtectedContainerView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 11.05.2026.
//

import UIKit

final class ScreenshotProtectedContainerView: UIView {
    // MARK: - UI Components
    let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let secureTextField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.isSecureTextEntry = false
        textField.isUserInteractionEnabled = false
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.text = " "
        return textField
    }()

    // MARK: - Properties
    private var didInstallContentView = false

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        installContentViewIfNeeded()
    }

    // MARK: - Methods
    func setSecureRenderingEnabled(_ isEnabled: Bool) {
        guard secureTextField.isSecureTextEntry != isEnabled else {
            return
        }

        secureTextField.isSecureTextEntry = isEnabled
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .clear
        clipsToBounds = true

        addSubview(secureTextField)
        secureTextField.pin(to: self)

        installContentViewIfNeeded()
    }

    private func installContentViewIfNeeded() {
        guard didInstallContentView == false else {
            return
        }

        secureTextField.layoutIfNeeded()

        guard let secureCanvasView = findSecureCanvasView(in: secureTextField) else {
            return
        }

        secureCanvasView.backgroundColor = .clear
        secureCanvasView.clipsToBounds = true
        secureCanvasView.addSubview(contentView)
        contentView.pin(to: secureCanvasView)
        didInstallContentView = true
    }

    private func findSecureCanvasView(in rootView: UIView) -> UIView? {
        allSubviews(of: rootView).first { subview in
            let className = NSStringFromClass(type(of: subview))
            return className.contains("LayoutCanvasView")
                || className.contains("TextLayoutCanvasView")
                || className.contains("CanvasView")
        }
    }

    private func allSubviews(of rootView: UIView) -> [UIView] {
        rootView.subviews.flatMap { subview in
            [subview] + allSubviews(of: subview)
        }
    }
}
