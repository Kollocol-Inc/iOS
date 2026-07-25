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
    private weak var secureCanvasView: UIView?

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
        DispatchQueue.main.async { [weak self] in
            self?.installContentViewIfNeeded()
        }
    }

    private func installContentViewIfNeeded() {
        secureTextField.layoutIfNeeded()

        guard let targetCanvasView = findSecureCanvasView(in: secureTextField) else {
            return
        }

        if contentView.superview !== targetCanvasView {
            contentView.removeFromSuperview()
            targetCanvasView.addSubview(contentView)
            contentView.pin(to: targetCanvasView)
        }

        targetCanvasView.backgroundColor = .clear
        targetCanvasView.clipsToBounds = true
        secureCanvasView = targetCanvasView
    }

    private func findSecureCanvasView(in rootView: UIView) -> UIView? {
        let candidates = allSubviews(of: rootView).filter { subview in
            let className = NSStringFromClass(type(of: subview))
            return className.contains("LayoutCanvasView")
                || className.contains("TextLayoutCanvasView")
                || className.contains("CanvasView")
        }

        guard candidates.isEmpty == false else {
            return nil
        }

        let rootWidth = rootView.bounds.width
        let rootHeight = rootView.bounds.height

        if let bestSizedCandidate = candidates.first(where: { candidate in
            abs(candidate.bounds.width - rootWidth) < 0.5
                && abs(candidate.bounds.height - rootHeight) < 0.5
        }) {
            return bestSizedCandidate
        }

        return candidates.max { lhs, rhs in
            (lhs.bounds.width * lhs.bounds.height) < (rhs.bounds.width * rhs.bounds.height)
        }
    }

    private func allSubviews(of rootView: UIView) -> [UIView] {
        rootView.subviews.flatMap { subview in
            [subview] + allSubviews(of: subview)
        }
    }
}
