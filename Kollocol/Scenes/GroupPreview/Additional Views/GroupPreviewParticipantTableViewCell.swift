//
//  GroupPreviewParticipantTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import UIKit

final class GroupPreviewParticipantTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "avatarPlaceholder")
        return imageView
    }()

    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let creatorCrownImageView: UIImageView = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "crown.fill", withConfiguration: imageConfiguration)?
            .withTintColor(.backgroundGold, renderingMode: .alwaysOriginal)
        imageView.isHidden = true
        return imageView
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        return button
    }()

    private let currentUserLabel: UILabel = {
        let label = UILabel()
        label.text = "you".localized
        label.textColor = .accentPrimary
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .right
        label.isHidden = true
        return label
    }()

    private let rightStatusContainerView = UIView()

    // MARK: - Constants
    static let reuseIdentifier = "GroupPreviewParticipantTableViewCell"

    private enum UIConstants {
        static let statusViewSize: CGFloat = 17
        static let avatarSize: CGFloat = 44
        static let avatarLeftInset: CGFloat = 28
        static let avatarBottomInset: CGFloat = 10
        static let textSpacingFromAvatar: CGFloat = 12
        static let statusRightInset: CGFloat = 24
        static let textSpacingFromStatus: CGFloat = 12
    }

    // MARK: - Properties
    private var rightStatusContainerWidthConstraint: NSLayoutConstraint?
    private var onActionTap: (() -> Void)?

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
    func configure(
        participant: GroupPreviewModels.ParticipantViewData,
        isActionEnabled: Bool,
        onActionTap: (() -> Void)?
    ) {
        self.onActionTap = onActionTap

        fullNameLabel.text = participant.fullName
        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailLabel.text = email
        emailLabel.isHidden = email.isEmpty
        avatarImageView.setImage(
            url: participant.avatarUrl,
            placeholder: UIImage(named: "avatarPlaceholder")
        )

        let contentAlpha: CGFloat = participant.isInvited ? 0.6 : 1
        avatarImageView.alpha = contentAlpha
        textStackView.alpha = contentAlpha

        applyRightAccessory(
            participant.rightAccessory,
            isActionEnabled: isActionEnabled
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textStackView.addArrangedSubview(fullNameLabel)
        textStackView.addArrangedSubview(emailLabel)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(rightStatusContainerView)

        rightStatusContainerView.addSubview(creatorCrownImageView)
        rightStatusContainerView.addSubview(currentUserLabel)
        rightStatusContainerView.addSubview(actionButton)

        avatarImageView.pinLeft(to: contentView.leadingAnchor, UIConstants.avatarLeftInset)
        avatarImageView.pinTop(to: contentView.topAnchor)
        avatarImageView.pinBottom(to: contentView.bottomAnchor, UIConstants.avatarBottomInset)
        avatarImageView.setWidth(UIConstants.avatarSize)
        avatarImageView.setHeight(UIConstants.avatarSize)

        rightStatusContainerView.pinRight(to: contentView.trailingAnchor, UIConstants.statusRightInset)
        rightStatusContainerView.pinCenterY(to: avatarImageView)
        rightStatusContainerWidthConstraint = rightStatusContainerView.setWidth(0)
        rightStatusContainerView.setHeight(UIConstants.statusViewSize)

        creatorCrownImageView.pinCenter(to: rightStatusContainerView)
        creatorCrownImageView.setWidth(UIConstants.statusViewSize)
        creatorCrownImageView.setHeight(UIConstants.statusViewSize)

        currentUserLabel.pin(to: rightStatusContainerView)

        actionButton.pinCenter(to: rightStatusContainerView)
        actionButton.setWidth(UIConstants.statusViewSize)
        actionButton.setHeight(UIConstants.statusViewSize)

        textStackView.pinLeft(to: avatarImageView.trailingAnchor, UIConstants.textSpacingFromAvatar)
        textStackView.pinCenterY(to: avatarImageView)
        textStackView.pinRight(to: rightStatusContainerView.leadingAnchor, UIConstants.textSpacingFromStatus)

        actionButton.addTarget(self, action: #selector(handleActionTap), for: .touchUpInside)
    }

    private func applyRightAccessory(
        _ accessory: GroupPreviewModels.RightAccessory,
        isActionEnabled: Bool
    ) {
        currentUserLabel.isHidden = true
        creatorCrownImageView.isHidden = true
        actionButton.isHidden = true
        actionButton.isEnabled = false
        actionButton.alpha = 1

        switch accessory {
        case .you:
            currentUserLabel.isHidden = false
            rightStatusContainerWidthConstraint?.constant = ceil(currentUserLabel.intrinsicContentSize.width)

        case .crown:
            creatorCrownImageView.isHidden = false
            rightStatusContainerWidthConstraint?.constant = UIConstants.statusViewSize

        case .kick:
            configureActionButton(
                systemName: "person.slash.fill",
                tintColor: .backgroundRedSecondary,
                isEnabled: isActionEnabled
            )

        case .removeInvite:
            configureActionButton(
                systemName: "xmark",
                tintColor: .backgroundRedSecondary,
                isEnabled: isActionEnabled
            )

        case .none:
            rightStatusContainerWidthConstraint?.constant = 0
        }
    }

    private func configureActionButton(
        systemName: String,
        tintColor: UIColor,
        isEnabled: Bool
    ) {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: UIConstants.statusViewSize, weight: .regular)
        actionButton.setImage(
            UIImage(systemName: systemName, withConfiguration: imageConfiguration)?
                .withTintColor(tintColor, renderingMode: .alwaysOriginal),
            for: .normal
        )
        actionButton.isHidden = false
        actionButton.isEnabled = isEnabled
        actionButton.alpha = isEnabled ? 1 : 0.5
        rightStatusContainerWidthConstraint?.constant = UIConstants.statusViewSize
    }

    // MARK: - Actions
    @objc
    private func handleActionTap() {
        onActionTap?()
    }
}
