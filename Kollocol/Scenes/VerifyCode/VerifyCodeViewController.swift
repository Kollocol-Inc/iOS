//
//  VerifyCodeViewController.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

final class VerifyCodeViewController: UIViewController {
    // MARK: - UI Components
    private let kollocolLabel: UILabel = {
        let label = UILabel()
        label.text = "Kollocol"
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let centralStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        return stack
    }()
    
    private lazy var enterCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "Введите код"
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let codeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 8
        return stack
    }()
    
    private lazy var codeField1: StripedLoadingTextField = makeCodeField(tag: 0)
    private lazy var codeField2: StripedLoadingTextField = makeCodeField(tag: 1)
    private lazy var codeField3: StripedLoadingTextField = makeCodeField(tag: 2)
    private lazy var codeField4: StripedLoadingTextField = makeCodeField(tag: 3)
    
    private let descLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Constants
    private enum UIConstants {
        static let descFont = UIFont.systemFont(ofSize: 16, weight: .bold)
        
        static let codeFieldWidth: CGFloat = 48
        static let codeFieldHeight: CGFloat = 70
        static let codeFieldCornerRadius: CGFloat = 14
        static let codeFieldFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let codeFieldTextColor: UIColor = .textPrimary
        static let codeFieldBgColor: UIColor = .dividerPrimary

        static let activeBorderWidth: CGFloat = 1.5
        static let shakeDuration: TimeInterval = 0.45
        
        static let keyboardSpacing: Double = 12
    }
    
    // MARK: - Properties
    private var interactor: VerifyCodeInteractor
    private let email: String
    
    private var codeFields: [StripedLoadingTextField] { [codeField1, codeField2, codeField3, codeField4] }
    private var isErrorState = false
    private var isSubmitting = false
    
    private var centralStackCenterYConstraint: NSLayoutConstraint?
    private var centralStackBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    init(interactor: VerifyCodeInteractor, email: String) {
        self.interactor = interactor
        self.email = email
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        configureUI()
        configureKeyboardObservers()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        focusFirstFieldIfPossible()
    }
    
    // MARK: - Methods
    @MainActor
    func showCodeValidationFailed() {
        isSubmitting = false

        codeFields.forEach {
            $0.stopAnimating()
            applyBorder(for: $0, state: .error)
        }

        isErrorState = true
        shakeCodeFields()
    }
    
    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureDescLabel()
        configureCodeFields()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    private func configureDescLabel() {
        let codeSentText = NSAttributedString(
            string: "Ваш код был отправлен на\n",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIConstants.descFont
            ]
        )

        let emailText = NSAttributedString(
            string: email,
            attributes: [
                .foregroundColor: UIColor.accentPrimary,
                .font: UIConstants.descFont
            ]
        )

        let fullText = NSMutableAttributedString()
        fullText.append(codeSentText)
        fullText.append(emailText)

        descLabel.attributedText = fullText
    }
    
    private func configureConstraints() {
        view.addSubview(kollocolLabel)
        kollocolLabel.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        kollocolLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 70)

        view.addSubview(centralStack)
        centralStack.addArrangedSubview(enterCodeLabel)
        centralStack.addArrangedSubview(codeStack)
        centralStack.addArrangedSubview(descLabel)

        centralStackCenterYConstraint = centralStack.pinCenterY(to: view.safeAreaLayoutGuide.centerYAnchor)
        centralStack.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        centralStack.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 16)
        
        centralStackBottomConstraint = centralStack.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, UIConstants.keyboardSpacing)
        centralStackBottomConstraint?.isActive = false
    }
    
    private func configureCodeFields() {
        codeStack.addArrangedSubview(codeField1)
        codeStack.addArrangedSubview(codeField2)
        codeStack.addArrangedSubview(codeField3)
        codeStack.addArrangedSubview(codeField4)

        codeFields.forEach {
            $0.delegate = self
            $0.keyboardType = .numberPad
            $0.textAlignment = .center
            $0.font = UIConstants.codeFieldFont
            $0.textColor = UIConstants.codeFieldTextColor
            $0.backgroundColor = UIConstants.codeFieldBgColor
            $0.layer.cornerRadius = UIConstants.codeFieldCornerRadius
            $0.clipsToBounds = true
            $0.setWidth(UIConstants.codeFieldWidth)
            $0.setHeight(UIConstants.codeFieldHeight)

            $0.layer.borderWidth = 0
            $0.layer.borderColor = UIColor.clear.cgColor

            $0.addTarget(self, action: #selector(codeFieldEditingChanged(_:)), for: .editingChanged)
            $0.addTarget(self, action: #selector(codeFieldDidBeginFocused(_:)), for: .editingDidBegin)
            $0.addTarget(self, action: #selector(codeFieldDidFinishFocused(_:)), for: .editingDidEnd)
        }
    }
    
    private func makeCodeField(tag: Int) -> VerifyCodeTextField {
        let field = VerifyCodeTextField()
        field.tag = tag
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.spellCheckingType = .no
        field.textContentType = tag == 0 ? .oneTimeCode : nil
        field.onBackspaceOnEmpty = { [weak self] textField in
            self?.handleBackspaceOnEmpty(textField)
        }
        field.onBackspaceAtBeginningWithText = { [weak self] textField in
            self?.handleBackspaceAtBeginningWithText(textField)
        }
        return field
    }
    
    private func focusFirstFieldIfPossible() {
        guard !isSubmitting else { return }
        if codeField1.window != nil {
            codeField1.becomeFirstResponder()
        }
    }
    
    private func currentCode() -> String? {
        let parts = codeFields.compactMap { $0.text }
        guard parts.count == 4, parts.allSatisfy({ $0.count == 1 }) else { return nil }
        return parts.joined()
    }

    private func submitIfReady() {
        guard !isSubmitting, let code = currentCode() else { return }

        isSubmitting = true
        isErrorState = false

        codeFields.forEach { applyBorder(for: $0, state: .inactive) }
        view.endEditing(true)

        codeFields.forEach {
            $0.startAnimating()
        }

        Task {
            await interactor.verify(code: code, with: email)
        }
    }
    
    private func setCode(_ digits: [String]) {
        for (idx, value) in digits.enumerated() where idx < codeFields.count {
            codeFields[idx].text = value
        }

        if digits.count < codeFields.count {
            codeFields[digits.count].becomeFirstResponder()
        } else {
            submitIfReady()
        }
    }
    
    private func clearErrorStateIfNeeded() {
        guard isErrorState else { return }
        isErrorState = false
        codeFields.forEach { applyBorder(for: $0, state: .inactive) }
    }

    private func clearFields(from index: Int) {
        guard index >= 0, index < codeFields.count else { return }
        for i in index..<codeFields.count {
            codeFields[i].text = nil
            codeFields[i].sendActions(for: .editingChanged)
        }
    }

    private func applyBorder(for field: StripedLoadingTextField, state: BorderState) {
        switch state {
        case .inactive:
            field.layer.borderWidth = 0
            field.layer.borderColor = UIColor.clear.cgColor
        case .active:
            field.layer.borderWidth = UIConstants.activeBorderWidth
            field.layer.borderColor = UIColor.accentPrimary.cgColor
        case .error:
            field.layer.borderWidth = UIConstants.activeBorderWidth
            field.layer.borderColor = UIColor.backgroundRed.cgColor
        }
    }
    
    private func shakeCodeFields() {
        let anim = CAKeyframeAnimation(keyPath: "transform.translation.x")
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        anim.duration = UIConstants.shakeDuration
        anim.values = [-10, 10, -8, 8, -6, 6, -4, 4, 0]

        codeFields.forEach {
            $0.layer.add(anim, forKey: "shake")
        }
    }
    
    private func moveFocusForward(from index: Int) {
        let nextIndex = index + 1
        if nextIndex < codeFields.count {
            codeFields[nextIndex].becomeFirstResponder()
        } else {
            submitIfReady()
        }
    }
    
    private func handleBackspaceOnEmpty(_ field: VerifyCodeTextField) {
        guard !isSubmitting else { return }

        let index = field.tag
        guard index > 0 else { return }

        let prev = codeFields[index - 1]
        prev.text = nil
        prev.becomeFirstResponder()
        prev.sendActions(for: .editingChanged)
    }

    private func handleBackspaceAtBeginningWithText(_ field: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        field.text = nil
        field.sendActions(for: .editingChanged)
    }
    
    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func applyKeyboardLayout(lift: CGFloat, duration: Double, options: UIView.AnimationOptions) {
        let isVisible = lift > 0.5
        
        if isVisible {
            centralStackBottomConstraint?.constant = -(lift + CGFloat(UIConstants.keyboardSpacing))
            centralStackCenterYConstraint?.isActive = false
            centralStackBottomConstraint?.isActive = true
        } else {
            centralStackBottomConstraint?.isActive = false
            centralStackCenterYConstraint?.isActive = true
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc
    private func codeFieldEditingChanged(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }

        let index = sender.tag
        if sender.text?.count == 1 {
            moveFocusForward(from: index)
        }
    }

    @objc
    private func codeFieldDidBeginFocused(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }

        if isErrorState {
            clearFields(from: sender.tag)
        }

        clearErrorStateIfNeeded()
        codeFields.forEach { applyBorder(for: $0, state: .inactive) }
        applyBorder(for: sender, state: .active)
    }

    @objc
    private func codeFieldDidFinishFocused(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        if !isErrorState {
            applyBorder(for: sender, state: .inactive)
        }
    }
    
    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let change = KeyboardChange(notification) else { return }

        let keyboardFrame = view.convert(change.endFrame, from: nil)
        let keyboardTop = keyboardFrame.minY
        let safeAreaBottom = view.safeAreaLayoutGuide.layoutFrame.maxY
        let lift = max(0, safeAreaBottom - keyboardTop)

        applyKeyboardLayout(lift: lift, duration: change.duration, options: change.options)
    }
}

// MARK: - BorderState
private enum BorderState {
    case inactive
    case active
    case error
}

// MARK: - UITextFieldDelegate
extension VerifyCodeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !isSubmitting else { return false }
        guard let field = textField as? VerifyCodeTextField else { return false }

        let digitsOnly = string.filter { $0.isNumber }
        if digitsOnly.count != string.count {
            return false
        }

        let index = field.tag

        if string.count > 1 {
            let chars = Array(string).map { String($0) }

            if chars.count == 4 {
                setCode(chars)
                return false
            }

            var buffer = codeFields.map { $0.text ?? "" }
            var writeIndex = index

            for ch in chars where writeIndex < buffer.count {
                buffer[writeIndex] = ch
                writeIndex += 1
            }

            setCode(buffer.map { $0.isEmpty ? "" : String($0.prefix(1)) })
            return false
        }

        if string.isEmpty {
            return true
        }

        field.text = string
        moveFocusForward(from: index)
        return false
    }
}
