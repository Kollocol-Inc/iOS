//
//  InputBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import UIKit

struct InputBottomSheetContent {
    let title: String
    let placeholder: String
    let buttonTitle: String
}

final class InputBottomSheetViewController: UIViewController {
    // MARK: - UI Components
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let promptTextView: StripedLoadingTextView = {
        let textView = StripedLoadingTextView()
        textView.backgroundColor = .dividerPrimary
        textView.textColor = .textSecondary
        textView.font = .systemFont(ofSize: 15, weight: .medium)
        textView.layer.cornerRadius = 18
        textView.textContainerInset = .init(top: 12, left: 10, bottom: 12, right: 10)
        textView.isScrollEnabled = false
        return textView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.numberOfLines = 0
        return label
    }()

    private let generateButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setHeight(44)
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let horizontalInset: CGFloat = 12
        static let topInset: CGFloat = 16
        static let titleToInputSpacing: CGFloat = 16
        static let inputToButtonSpacing: CGFloat = 16
        static let bottomInset: CGFloat = 0
        static let minTextViewHeight: CGFloat = 88
        static let maxTextViewHeight: CGFloat = 220
    }

    // MARK: - Properties
    var onGenerate: ((String) -> Void)?
    var onExitWhileGenerating: (() -> Void)?

    private let content: InputBottomSheetContent
    private var promptTextViewHeightConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    private var lastMeasuredHeight: CGFloat = 0
    private var keyboardBottomInset: CGFloat = 0
    private var isGenerating = false

    // MARK: - Lifecycle
    init(content: InputBottomSheetContent) {
        self.content = content
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
        presentationController?.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePromptTextViewHeightIfNeeded()
        updatePreferredContentSizeIfNeeded()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Methods
    func preferredSheetHeight(maximumDetentValue: CGFloat) -> CGFloat {
        loadViewIfNeeded()

        let fallbackWidth = view.window?.windowScene?.screen.bounds.width ?? view.bounds.width
        let layoutWidth = view.bounds.width > 0 ? view.bounds.width : fallbackWidth
        let horizontalInsets = UIConstants.horizontalInset * 2
        let contentWidth = max(0, layoutWidth - horizontalInsets)

        let fittingSize = contentStackView.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let measuredHeight = fittingSize.height
            + UIConstants.topInset
            + UIConstants.bottomInset
            + keyboardBottomInset
        return min(measuredHeight, maximumDetentValue)
    }

    func startGenerating() {
        guard isGenerating == false else { return }

        isGenerating = true
        isModalInPresentation = true
        promptTextView.startAnimating()
        updateGenerateButtonState()
    }

    func stopGenerating() {
        guard isGenerating else { return }

        isGenerating = false
        isModalInPresentation = false
        promptTextView.stopAnimating()
        updateGenerateButtonState()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.backgroundColor = .backgroundSecondary
        configureContent()
        configureLayoutPriorities()
        configureConstraints()
        configureActions()
        updateGenerateButtonState()
    }

    private func configureContent() {
        titleLabel.text = content.title
        placeholderLabel.text = content.placeholder
        updatePlaceholderVisibility()

        generateButton.setAttributedTitle(
            NSAttributedString(
                string: content.buttonTitle,
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
    }

    private func configureLayoutPriorities() {
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        generateButton.setContentHuggingPriority(.required, for: .vertical)
        generateButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func configureConstraints() {
        view.addSubview(contentStackView)
        contentStackView.pinTop(to: view.topAnchor, UIConstants.topInset)
        contentStackView.pinLeft(to: view.leadingAnchor, UIConstants.horizontalInset)
        contentStackView.pinRight(to: view.trailingAnchor, UIConstants.horizontalInset)
        contentBottomConstraint = contentStackView.pinBottom(
            to: view.safeAreaLayoutGuide.bottomAnchor,
            UIConstants.bottomInset,
            .lsOE
        )

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.setCustomSpacing(UIConstants.titleToInputSpacing, after: titleLabel)
        contentStackView.addArrangedSubview(promptTextView)
        contentStackView.setCustomSpacing(UIConstants.inputToButtonSpacing, after: promptTextView)
        contentStackView.addArrangedSubview(generateButton)

        promptTextViewHeightConstraint = promptTextView.setHeight(UIConstants.minTextViewHeight)
        promptTextView.delegate = self

        promptTextView.addSubview(placeholderLabel)
        placeholderLabel.pinTop(to: promptTextView.topAnchor, 12)
        placeholderLabel.pinLeft(to: promptTextView.leadingAnchor, 14)
        placeholderLabel.pinRight(to: promptTextView.trailingAnchor, 14)
    }

    private func configureActions() {
        generateButton.addTarget(self, action: #selector(handleGenerateTap), for: .touchUpInside)
    }

    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func updateGenerateButtonState() {
        let normalizedPrompt = promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEnabled = normalizedPrompt.isEmpty == false && isGenerating == false
        generateButton.isEnabled = isEnabled
        generateButton.alpha = isEnabled ? 1 : 0.6
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = promptTextView.text.isEmpty == false
    }

    private func updatePromptTextViewHeightIfNeeded() {
        let currentWidth = promptTextView.bounds.width
        guard currentWidth > 0 else { return }

        let fittingSize = promptTextView.sizeThatFits(
            CGSize(width: currentWidth, height: .greatestFiniteMagnitude)
        )
        let targetHeight = min(
            max(fittingSize.height, UIConstants.minTextViewHeight),
            UIConstants.maxTextViewHeight
        )

        promptTextView.isScrollEnabled = fittingSize.height > UIConstants.maxTextViewHeight

        guard let promptTextViewHeightConstraint else { return }
        guard abs(promptTextViewHeightConstraint.constant - targetHeight) > 0.5 else { return }

        promptTextViewHeightConstraint.constant = targetHeight
        updatePreferredContentSizeIfNeeded()
    }

    private func updatePreferredContentSizeIfNeeded() {
        let measuredHeight = preferredSheetHeight(maximumDetentValue: .greatestFiniteMagnitude)
        guard abs(lastMeasuredHeight - measuredHeight) > 0.5 else { return }

        lastMeasuredHeight = measuredHeight
        preferredContentSize = CGSize(width: view.bounds.width, height: measuredHeight)

        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    private func applyKeyboardInset(
        _ bottomInset: CGFloat,
        duration: Double,
        options: UIView.AnimationOptions
    ) {
        keyboardBottomInset = max(0, bottomInset)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.contentBottomConstraint?.constant = -1 * self.keyboardBottomInset
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollFirstResponderAboveKeyboard()
            self.updatePreferredContentSizeIfNeeded()
        }
    }

    private func scrollFirstResponderAboveKeyboard() {
        guard keyboardBottomInset > 0 else {
            contentStackView.transform = .identity
            return
        }

        guard let firstResponder = findFirstResponder(in: view) else {
            contentStackView.transform = .identity
            return
        }

        let responderFrame = firstResponder.convert(firstResponder.bounds, to: view)
        let visibleBounds = view.bounds.insetBy(dx: 0, dy: keyboardBottomInset)
        let requiredOffset = max(0, responderFrame.maxY - visibleBounds.maxY + 12)
        contentStackView.transform = CGAffineTransform(translationX: 0, y: -requiredOffset)
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }

        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }

        return nil
    }

    private var hasUnsavedChanges: Bool {
        promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func handleDismissAttemptWhileGenerating() {
        showConfirmationAlert(
            title: "Внимание",
            message: "Генерация шаблона в процессе. Вы уверены, что хотите выйти?",
            cancelTitle: "Отмена",
            confirmTitle: "Выйти",
            confirmStyle: .destructive
        ) { [weak self] in
            guard let self else { return }
            onExitWhileGenerating?()
            dismiss(animated: true)
        }
    }

    private func handleDismissAttemptWithUnsavedChanges() {
        showConfirmationAlert(
            title: "Внимание",
            message: "Вы уверены, что хотите выйти? Все изменения будут утеряны безвозвратно",
            cancelTitle: "Отмена",
            confirmTitle: "Выйти",
            confirmStyle: .destructive
        ) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let change = KeyboardChange(notification) else { return }

        let keyboardFrame = view.convert(change.endFrame, from: nil)
        let keyboardTop = keyboardFrame.minY
        let safeAreaBottom = view.safeAreaLayoutGuide.layoutFrame.maxY
        let lift = max(0, safeAreaBottom - keyboardTop)

        applyKeyboardInset(lift, duration: change.duration, options: change.options)
    }

    // MARK: - Actions
    @objc
    private func handleGenerateTap() {
        let normalizedPrompt = promptTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedPrompt.isEmpty == false else { return }
        onGenerate?(normalizedPrompt)
    }
}

// MARK: - UITextViewDelegate
extension InputBottomSheetViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        scrollFirstResponderAboveKeyboard()
    }

    func textViewDidChange(_ textView: UITextView) {
        updatePlaceholderVisibility()
        updateGenerateButtonState()
        updatePromptTextViewHeightIfNeeded()
        updatePreferredContentSizeIfNeeded()
    }
}

// MARK: - AlertPresenting
extension InputBottomSheetViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension InputBottomSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        isGenerating == false && hasUnsavedChanges == false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if isGenerating {
            handleDismissAttemptWhileGenerating()
            return
        }

        if hasUnsavedChanges {
            handleDismissAttemptWithUnsavedChanges()
        }
    }
}
