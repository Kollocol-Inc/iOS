//
//  InfoBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 09.03.2026.
//

import UIKit

enum InfoBottomSheetActionIdentifier: Equatable {
    case confirm
    case cancel
    case custom(String)
}

enum InfoBottomSheetActionStyle {
    case accentPrimary
    case buttonSecondary
    case backgroundRedSecondary
}

struct InfoBottomSheetAction {
    let identifier: InfoBottomSheetActionIdentifier
    let title: String
    let style: InfoBottomSheetActionStyle
    let autoDismiss: Bool

    init(
        identifier: InfoBottomSheetActionIdentifier,
        title: String,
        style: InfoBottomSheetActionStyle,
        autoDismiss: Bool = true
    ) {
        self.identifier = identifier
        self.title = title
        self.style = style
        self.autoDismiss = autoDismiss
    }
}

enum InfoBottomSheetButtonsConfiguration {
    case single(action: InfoBottomSheetAction)
    case double(left: InfoBottomSheetAction, right: InfoBottomSheetAction)
}

struct InfoBottomSheetContent {
    let title: String
    let description: String
    let buttonsConfiguration: InfoBottomSheetButtonsConfiguration

    var buttonTitle: String {
        switch buttonsConfiguration {
        case .single(let action):
            return action.title
        case .double:
            return "ОК"
        }
    }

    init(title: String, description: String, buttonTitle: String = "ОК") {
        self.init(
            title: title,
            description: description,
            buttonsConfiguration: .single(
                action: InfoBottomSheetAction(
                    identifier: .confirm,
                    title: buttonTitle,
                    style: .accentPrimary
                )
            )
        )
    }

    init(
        title: String,
        description: String,
        buttonsConfiguration: InfoBottomSheetButtonsConfiguration
    ) {
        self.title = title
        self.description = description
        self.buttonsConfiguration = buttonsConfiguration
    }
}

final class InfoBottomSheetViewController: UIViewController {
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

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setHeight(44)
        return button
    }()

    private let leftActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .backgroundRedSecondary
        button.layer.cornerRadius = 18
        button.setHeight(44)
        return button
    }()

    private let rightActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setHeight(44)
        return button
    }()

    private let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        stackView.isHidden = true
        return stackView
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let horizontalInset: CGFloat = 12
        static let topInset: CGFloat = 16
        static let titleToDescriptionSpacing: CGFloat = 16
        static let descriptionToButtonSpacing: CGFloat = 16
        static let bottomInset: CGFloat = 0
    }

    // MARK: - Properties
    private let content: InfoBottomSheetContent
    private let onAction: ((InfoBottomSheetActionIdentifier) -> Void)?
    private var lastMeasuredHeight: CGFloat = 0
    private var singleAction: InfoBottomSheetAction?
    private var leftAction: InfoBottomSheetAction?
    private var rightAction: InfoBottomSheetAction?

    // MARK: - Lifecycle
    init(
        content: InfoBottomSheetContent,
        onAction: ((InfoBottomSheetActionIdentifier) -> Void)? = nil
    ) {
        self.content = content
        self.onAction = onAction
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeIfNeeded()
    }

    // MARK: - Methods
    func preferredSheetHeight(maximumDetentValue: CGFloat) -> CGFloat {
        loadViewIfNeeded()

        let layoutWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        let horizontalInsets = UIConstants.horizontalInset * 2
        let contentWidth = max(0, layoutWidth - horizontalInsets)

        let fittingSize = contentStackView.systemLayoutSizeFitting(
            CGSize(width: contentWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        let measuredHeight = fittingSize.height + UIConstants.topInset + UIConstants.bottomInset
        return min(measuredHeight, maximumDetentValue)
    }

    // MARK: - Private Methods
    private func configureUI() {
        isModalInPresentation = false
        view.backgroundColor = .backgroundSecondary

        configureContent()
        configureLayoutPriorities()
        configureConstraints()
        configureActions()
    }

    private func configureContent() {
        titleLabel.text = content.title
        descriptionLabel.text = content.description

        switch content.buttonsConfiguration {
        case .single(let action):
            singleAction = action
            leftAction = nil
            rightAction = nil

            confirmButton.isHidden = false
            actionsStackView.isHidden = true
            apply(action: action, to: confirmButton)

        case .double(let left, let right):
            singleAction = nil
            leftAction = left
            rightAction = right

            confirmButton.isHidden = true
            actionsStackView.isHidden = false
            apply(action: left, to: leftActionButton)
            apply(action: right, to: rightActionButton)
        }
    }

    private func configureConstraints() {
        view.addSubview(contentStackView)
        contentStackView.pinTop(to: view.topAnchor, UIConstants.topInset)
        contentStackView.pinLeft(to: view.leadingAnchor, UIConstants.horizontalInset)
        contentStackView.pinRight(to: view.trailingAnchor, UIConstants.horizontalInset)
        contentStackView.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, UIConstants.bottomInset, .lsOE)

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.setCustomSpacing(UIConstants.titleToDescriptionSpacing, after: titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.setCustomSpacing(UIConstants.descriptionToButtonSpacing, after: descriptionLabel)
        contentStackView.addArrangedSubview(confirmButton)
        contentStackView.addArrangedSubview(actionsStackView)

        actionsStackView.addArrangedSubview(leftActionButton)
        actionsStackView.addArrangedSubview(rightActionButton)
    }

    private func configureLayoutPriorities() {
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        confirmButton.setContentHuggingPriority(.required, for: .vertical)
        confirmButton.setContentCompressionResistancePriority(.required, for: .vertical)
        leftActionButton.setContentHuggingPriority(.required, for: .vertical)
        leftActionButton.setContentCompressionResistancePriority(.required, for: .vertical)
        rightActionButton.setContentHuggingPriority(.required, for: .vertical)
        rightActionButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func configureActions() {
        confirmButton.addTarget(self, action: #selector(handleConfirmTap), for: .touchUpInside)
        leftActionButton.addTarget(self, action: #selector(handleLeftActionTap), for: .touchUpInside)
        rightActionButton.addTarget(self, action: #selector(handleRightActionTap), for: .touchUpInside)
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

    private func apply(action: InfoBottomSheetAction, to button: UIButton) {
        button.backgroundColor = backgroundColor(for: action.style)
        button.setAttributedTitle(
            NSAttributedString(
                string: action.title,
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
    }

    private func backgroundColor(for style: InfoBottomSheetActionStyle) -> UIColor {
        switch style {
        case .accentPrimary:
            return .accentPrimary
        case .buttonSecondary:
            return .buttonSecondary
        case .backgroundRedSecondary:
            return .backgroundRedSecondary
        }
    }

    private func perform(action: InfoBottomSheetAction?) {
        guard let action else {
            return
        }

        if action.autoDismiss {
            dismiss(animated: true) { [weak self] in
                self?.onAction?(action.identifier)
            }
            return
        }

        onAction?(action.identifier)
    }

    // MARK: - Actions
    @objc
    private func handleConfirmTap() {
        perform(action: singleAction)
    }

    @objc
    private func handleLeftActionTap() {
        perform(action: leftAction)
    }

    @objc
    private func handleRightActionTap() {
        perform(action: rightAction)
    }
}
