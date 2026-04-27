//
//  QuizWaitingRoomParticipantTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizWaitingRoomParticipantTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let offlineStatusImageView: UIImageView = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(
            systemName: "antenna.radiowaves.left.and.right.slash",
            withConfiguration: imageConfiguration
        )?.withTintColor(.backgroundRedSecondary, renderingMode: .alwaysOriginal)
        imageView.isHidden = true
        return imageView
    }()

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

    private let nameLabel: UILabel = {
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

    private let kickParticipantButton: UIButton = {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let button = UIButton(type: .system)
        button.setImage(
            UIImage(systemName: "person.slash.fill", withConfiguration: imageConfiguration)?
                .withTintColor(.backgroundRedSecondary, renderingMode: .alwaysOriginal),
            for: .normal
        )
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
    static let reuseIdentifier = "QuizWaitingRoomParticipantTableViewCell"

    // MARK: - Properties
    private var rightStatusContainerWidthConstraint: NSLayoutConstraint?
    private var onKickTap: (() -> Void)?

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
        participant: QuizParticipant?,
        isCurrentUser: Bool = false,
        isOffline: Bool = false,
        canKickParticipant: Bool = false,
        onKickTap: (() -> Void)? = nil
    ) {
        self.onKickTap = onKickTap

        guard let participant else {
            nameLabel.text = "participant".localized
            emailLabel.text = nil
            emailLabel.isHidden = true
            avatarImageView.image = UIImage(named: "avatarPlaceholder")
            applyRightStatusState(isCreator: false, isCurrentUser: false, canKickParticipant: false)
            applyOnlineState(isOffline: false)
            return
        }

        let name = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        nameLabel.text = name.isEmpty ? "participant".localized : name

        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailLabel.text = email
        emailLabel.isHidden = email.isEmpty

        avatarImageView.setImage(
            url: participant.avatarURL,
            placeholder: UIImage(named: "avatarPlaceholder")
        )
        applyRightStatusState(
            isCreator: participant.isCreator,
            isCurrentUser: isCurrentUser,
            canKickParticipant: canKickParticipant
        )
        applyOnlineState(isOffline: isOffline)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(emailLabel)

        contentView.addSubview(offlineStatusImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(rightStatusContainerView)
        rightStatusContainerView.addSubview(creatorCrownImageView)
        rightStatusContainerView.addSubview(currentUserLabel)
        rightStatusContainerView.addSubview(kickParticipantButton)

        offlineStatusImageView.pinRight(to: avatarImageView.leadingAnchor, 4)
        offlineStatusImageView.pinCenterY(to: avatarImageView)
        offlineStatusImageView.setWidth(17)
        offlineStatusImageView.setHeight(17)

        avatarImageView.pinLeft(to: contentView.leadingAnchor, 28)
        avatarImageView.pinTop(to: contentView.topAnchor, 0)
        avatarImageView.pinBottom(to: contentView.bottomAnchor, 10)
        avatarImageView.setWidth(44)
        avatarImageView.setHeight(44)

        rightStatusContainerView.pinRight(to: contentView.trailingAnchor, 24)
        rightStatusContainerView.pinCenterY(to: avatarImageView)
        rightStatusContainerWidthConstraint = rightStatusContainerView.setWidth(0)
        rightStatusContainerView.setHeight(17)

        creatorCrownImageView.pinCenter(to: rightStatusContainerView)
        creatorCrownImageView.setWidth(17)
        creatorCrownImageView.setHeight(17)

        currentUserLabel.pin(to: rightStatusContainerView)

        kickParticipantButton.pinCenter(to: rightStatusContainerView)
        kickParticipantButton.setWidth(17)
        kickParticipantButton.setHeight(17)

        textStackView.pinLeft(to: avatarImageView.trailingAnchor, 12)
        textStackView.pinCenterY(to: avatarImageView)
        textStackView.pinRight(to: rightStatusContainerView.leadingAnchor, 12)

        kickParticipantButton.addTarget(self, action: #selector(handleKickTap), for: .touchUpInside)
    }

    private func applyRightStatusState(isCreator: Bool, isCurrentUser: Bool, canKickParticipant: Bool) {
        let shouldShowCurrentUserLabel = isCurrentUser
        let shouldShowCreatorCrown = isCurrentUser == false && isCreator
        let shouldShowKickButton = isCurrentUser == false && isCreator == false && canKickParticipant

        currentUserLabel.isHidden = shouldShowCurrentUserLabel == false
        creatorCrownImageView.isHidden = shouldShowCreatorCrown == false
        kickParticipantButton.isHidden = shouldShowKickButton == false

        if shouldShowCurrentUserLabel {
            let textWidth = ceil(currentUserLabel.intrinsicContentSize.width)
            rightStatusContainerWidthConstraint?.constant = textWidth
            return
        }

        if shouldShowCreatorCrown || shouldShowKickButton {
            rightStatusContainerWidthConstraint?.constant = 17
            return
        }

        rightStatusContainerWidthConstraint?.constant = 0
    }

    private func applyOnlineState(isOffline: Bool) {
        offlineStatusImageView.isHidden = isOffline == false
        let contentAlpha: CGFloat = isOffline ? 0.6 : 1
        avatarImageView.alpha = contentAlpha
        textStackView.alpha = contentAlpha
        rightStatusContainerView.alpha = contentAlpha
    }

    // MARK: - Actions
    @objc
    private func handleKickTap() {
        onKickTap?()
    }
}
