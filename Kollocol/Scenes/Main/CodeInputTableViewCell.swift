//
//  CodeInputTableViewCell.swift
//  Kollocol
//
//  Created by Arseniy on 28.02.2026.
//

import UIKit

final class CodeInputTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "CodeInputTableViewCell"
    
    private enum UIConstants {
        static let codeFieldHeight: CGFloat = 70
        static let codeFieldCornerRadius: CGFloat = 14
        static let codeFieldFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let codeFieldTextColor: UIColor = .textPrimary
        static let codeFieldBgColor: UIColor = .accentPrimary.withAlphaComponent(0.3)
        static let activeBorderWidth: CGFloat = 1.5
        static let shakeDuration: TimeInterval = 0.45
    }
    
    // MARK: - UI Components
    private let codeStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()
    
    private lazy var codeField1: StripedLoadingTextField = makeCodeField(tag: 0)
    private lazy var codeField2: StripedLoadingTextField = makeCodeField(tag: 1)
    private lazy var codeField3: StripedLoadingTextField = makeCodeField(tag: 2)
    private lazy var codeField4: StripedLoadingTextField = makeCodeField(tag: 3)
    private lazy var codeField5: StripedLoadingTextField = makeCodeField(tag: 4)
    private lazy var codeField6: StripedLoadingTextField = makeCodeField(tag: 5)
    
    // MARK: - Properties
    var onCodeChanged: ((String?) -> Void)?
    
    private var codeFields: [StripedLoadingTextField] {
        [codeField1, codeField2, codeField3, codeField4, codeField5, codeField6]
    }
    
    private var isSubmitting = false
    
    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods
    func startAnimating() {
        isSubmitting = true
        codeFields.forEach {
            $0.startAnimating()
            applyBorder(for: $0, state: .inactive)
        }
        endEditing(true)
    }
    
    func stopAnimating() {
        isSubmitting = false
        codeFields.forEach {
            $0.stopAnimating()
        }
    }
    
    func resetFields() {
        stopAnimating()
        codeFields.forEach {
            $0.text = nil
            applyBorder(for: $0, state: .inactive)
        }
    }
    
    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(codeStack)
        codeStack.pinLeft(to: contentView.leadingAnchor, 32)
        codeStack.pinRight(to: contentView.trailingAnchor, 32)
        codeStack.pinTop(to: contentView.topAnchor, 16)
        codeStack.pinBottom(to: contentView.bottomAnchor, 8)
        
        configureCodeFields()
    }
    
    private func configureCodeFields() {
        codeFields.forEach {
            codeStack.addArrangedSubview($0)
            
            $0.delegate = self
            $0.keyboardType = .numberPad
            $0.textAlignment = .center
            $0.font = UIConstants.codeFieldFont
            $0.textColor = UIConstants.codeFieldTextColor
            $0.backgroundColor = UIConstants.codeFieldBgColor
            $0.layer.cornerRadius = UIConstants.codeFieldCornerRadius
            $0.clipsToBounds = true
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
    
    private func currentCode() -> String? {
        let parts = codeFields.compactMap { $0.text }
        guard parts.count == 6, parts.allSatisfy({ $0.count == 1 }) else { return nil }
        return parts.joined()
    }
    
    private func notifyCodeChanged() {
        onCodeChanged?(currentCode())
    }
    
    private func setCode(_ digits: [String]) {
        for (idx, value) in digits.enumerated() where idx < codeFields.count {
            codeFields[idx].text = value
        }
        
        if digits.count < codeFields.count {
            codeFields[digits.count].becomeFirstResponder()
        } else {
            codeFields.last?.resignFirstResponder()
        }
        notifyCodeChanged()
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
        }
    }
    
    private func moveFocusForward(from index: Int) {
        let nextIndex = index + 1
        if nextIndex < codeFields.count {
            codeFields[nextIndex].becomeFirstResponder()
        } else {
            codeFields[index].resignFirstResponder()
        }
        notifyCodeChanged()
    }
    
    private func handleBackspaceOnEmpty(_ field: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        
        let index = field.tag
        guard index > 0 else { return }
        
        let prev = codeFields[index - 1]
        prev.text = nil
        prev.becomeFirstResponder()
        prev.sendActions(for: .editingChanged)
        notifyCodeChanged()
    }
    
    private func handleBackspaceAtBeginningWithText(_ field: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        field.text = nil
        field.sendActions(for: .editingChanged)
        notifyCodeChanged()
    }
    
    // MARK: - Actions
    @objc
    private func codeFieldEditingChanged(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        
        let index = sender.tag
        if sender.text?.count == 1 {
            moveFocusForward(from: index)
        } else if sender.text?.isEmpty == true {
            notifyCodeChanged()
        }
    }
    
    @objc
    private func codeFieldDidBeginFocused(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        
        clearFields(from: sender.tag)
        codeFields.forEach { applyBorder(for: $0, state: .inactive) }
        applyBorder(for: sender, state: .active)
    }
    
    @objc
    private func codeFieldDidFinishFocused(_ sender: VerifyCodeTextField) {
        guard !isSubmitting else { return }
        applyBorder(for: sender, state: .inactive)
    }
}

// MARK: - BorderState
private enum BorderState {
    case inactive
    case active
}

// MARK: - UITextFieldDelegate
extension CodeInputTableViewCell: UITextFieldDelegate {
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
            
            if chars.count == 6 {
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
