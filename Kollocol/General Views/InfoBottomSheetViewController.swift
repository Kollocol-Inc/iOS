//
//  InfoBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 09.03.2026.
//

import UIKit

struct InfoBottomSheetContent {
    let title: String
    let description: String
    let buttonTitle: String

    init(title: String, description: String, buttonTitle: String = "ОК") {
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
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
        button.setAttributedTitle(
            NSAttributedString(
                string: "ОК",
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
        button.setHeight(44)
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let horizontalInset: CGFloat = 12
        static let topInset: CGFloat = 16
        static let titleToDescriptionSpacing: CGFloat = 16
        static let descriptionToButtonSpacing: CGFloat = 16
        static let bottomInset: CGFloat = 8
    }

    // MARK: - Properties
    private let content: InfoBottomSheetContent
    private var lastMeasuredHeight: CGFloat = 0

    // MARK: - Lifecycle
    init(content: InfoBottomSheetContent) {
        self.content = content
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

        confirmButton.setAttributedTitle(
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
    }

    private func configureLayoutPriorities() {
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        descriptionLabel.setContentHuggingPriority(.required, for: .vertical)
        descriptionLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        confirmButton.setContentHuggingPriority(.required, for: .vertical)
        confirmButton.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func configureActions() {
        confirmButton.addTarget(self, action: #selector(handleConfirmTap), for: .touchUpInside)
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

    // MARK: - Actions
    @objc
    private func handleConfirmTap() {
        dismiss(animated: true)
    }
}
