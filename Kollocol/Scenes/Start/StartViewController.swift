//
//  StartViewController.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

final class StartViewController: UIViewController {
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
        stack.alignment = .fill
        stack.spacing = 16
        return stack
    }()
    
    private let emailLabel: UILabel = {
        let label = UILabel()
        label.text = "Введите вашу почту"
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private let emailTextField: StripedLoadingTextField = {
        let field = StripedLoadingTextField()
        let attributedPlaceholder = NSAttributedString(
            string: "example@kollocol.app",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
        )
        field.attributedPlaceholder = attributedPlaceholder
        field.autocorrectionType = .no
        field.autocapitalizationType = .none
        field.keyboardType = .emailAddress
        field.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        field.textColor = .textPrimary
        field.backgroundColor = .dividerPrimary
        field.addPadding(side: 10)
        field.layer.cornerRadius = 18
        field.setHeight(38)
        return field
    }()
    
    private let sendCodeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(Constants.SendCodeButtonTitles.disabled, for: .disabled)
        button.setAttributedTitle(Constants.SendCodeButtonTitles.active, for: .normal)
        button.tintColor = .textWhite
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.isEnabled = false
        button.alpha = 0.6
        button.setHeight(42)
        return button
    }()
    
    private lazy var sendCodeLoader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .textWhite
        view.hidesWhenStopped = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Constants
    private let baseButtonBottomInset: Double = 30
    private let stackToButtonSpacing: Double = 24
    private let keyboardSpacing: Double = 12
    
    // MARK: - Properties
    private var interactor: StartInteractor
    
    private var sendCodeButtonBottomConstraint: NSLayoutConstraint?
    private var centralStackCenterYConstraint: NSLayoutConstraint?
    private var centralStackBottomToButtonConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    init(interactor: StartInteractor) {
        self.interactor = interactor
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
    
    // MARK: - Methods
    @MainActor
    func showError() {
        sendCodeButton.isEnabled = true
        sendCodeButton.setAttributedTitle(Constants.SendCodeButtonTitles.active, for: .normal)
        sendCodeButton.setAttributedTitle(Constants.SendCodeButtonTitles.disabled, for: .disabled)
        sendCodeLoader.stopAnimating()
        emailTextField.stopAnimating()
    }
    
    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureActions()
        configureEmailTextField()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    private func configureEmailTextField() {
        emailTextField.returnKeyType = .done
        emailTextField.enablesReturnKeyAutomatically = true
        emailTextField.delegate = self
    }
    
    private func configureConstraints() {
        view.addSubview(kollocolLabel)
        kollocolLabel.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        kollocolLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 70)

        view.addSubview(centralStack)
        centralStack.addArrangedSubview(emailLabel)
        centralStack.addArrangedSubview(emailTextField)

        centralStackCenterYConstraint = centralStack.pinCenterY(to: view.safeAreaLayoutGuide.centerYAnchor)
        centralStack.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        centralStack.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 16)

        view.addSubview(sendCodeButton)
        sendCodeButton.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        sendCodeButton.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 16)
        sendCodeButtonBottomConstraint = sendCodeButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, baseButtonBottomInset)
        
        sendCodeButton.addSubview(sendCodeLoader)
        sendCodeLoader.pinCenter(to: sendCodeButton)

        centralStackBottomToButtonConstraint = centralStack.pinBottom(to: sendCodeButton.topAnchor, keyboardSpacing)
        centralStackBottomToButtonConstraint?.isActive = false
    }
    
    private func configureActions() {
        emailTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldDidBeginFocused), for: .editingDidBegin)
        emailTextField.addTarget(self, action: #selector(textFieldDidFinishFocused), for: .editingDidEnd)
        sendCodeButton.addTarget(self, action: #selector(sendCodeButtonPressed), for: .touchUpInside)
    }
    
    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func applyKeyboardLayout(lift: CGFloat, duration: Double, options: UIView.AnimationOptions) {
        let isVisible = lift > 0.5

        if isVisible {
            sendCodeButtonBottomConstraint?.constant = -(lift + CGFloat(keyboardSpacing))
            centralStackCenterYConstraint?.isActive = false
            centralStackBottomToButtonConstraint?.isActive = true
        } else {
            sendCodeButtonBottomConstraint?.constant = -CGFloat(baseButtonBottomInset)
            centralStackBottomToButtonConstraint?.isActive = false
            centralStackCenterYConstraint?.isActive = true
        }

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Actions
    @objc
    private func sendCodeButtonPressed() {
        guard let email = emailTextField.text else { return }
        
        sendCodeButton.isEnabled = false
        sendCodeButton.setAttributedTitle(nil, for: .normal)
        sendCodeButton.setAttributedTitle(nil, for: .disabled)
        sendCodeLoader.startAnimating()
        emailTextField.startAnimating()
        
        Task { await interactor.login(with: email) }
    }
    
    @objc
    private func textFieldDidChange() {
        let isValid = emailTextField.text?.isValidEmail == true

        UIView.performWithoutAnimation {
            sendCodeButton.isEnabled = isValid
            sendCodeButton.alpha = isValid ? 1 : 0.6
            sendCodeButton.layoutIfNeeded()
        }
    }

    
    @objc
    private func textFieldDidBeginFocused() {
        emailTextField.setFocusedBorder(isActive: true)
    }
    
    @objc
    private func textFieldDidFinishFocused() {
        emailTextField.setFocusedBorder(isActive: false)
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

private enum Constants {
    enum SendCodeButtonTitles {
        static let disabled = NSAttributedString(
            string: "Неверный формат почты",
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )

        static let active = NSAttributedString(
            string: "Отправить код",
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )
    }
}

// MARK: - UITextFieldDelegate
extension StartViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField === emailTextField else { return true }
        guard sendCodeButton.isEnabled else { return false }
        sendCodeButton.sendActions(for: .touchUpInside)
        return false
    }
}
