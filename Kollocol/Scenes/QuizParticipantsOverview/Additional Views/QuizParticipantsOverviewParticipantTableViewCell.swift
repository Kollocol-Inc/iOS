//
//  QuizParticipantsOverviewParticipantTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantsOverviewParticipantTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let leftStatusImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
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

    private let chevronImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20, weight: .medium))
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(systemName: "chevron.right", withConfiguration: configuration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        return imageView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantsOverviewParticipantTableViewCell"

    private enum UIConstants {
        static let leadingInset: CGFloat = 28
        static let statusToAvatarSpacing: CGFloat = 12
        static let statusSymbolSize: CGFloat = 20
        static let chevronSymbolSize: CGFloat = 20
    }

    // MARK: - Properties
    private var leftStatusWidthConstraint: NSLayoutConstraint?
    private var avatarLeadingConstraintToContent: NSLayoutConstraint?
    private var avatarLeadingConstraintToStatus: NSLayoutConstraint?
    private var chevronWidthConstraint: NSLayoutConstraint?

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
    func configure(with data: QuizParticipantsOverviewModels.ParticipantRowData) {
        nameLabel.text = data.fullName

        let email = data.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailLabel.text = email
        emailLabel.isHidden = email.isEmpty

        avatarImageView.setImage(
            url: data.avatarURL,
            placeholder: UIImage(named: "avatarPlaceholder")
        )

        applyLeftStatusIcon(data.leftStatusIcon)
        applyChevronVisibility(data.showsChevron)
        applyDimmedState(data.isDimmed)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(emailLabel)

        contentView.addSubview(leftStatusImageView)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(chevronImageView)

        leftStatusImageView.pinLeft(to: contentView.leadingAnchor, UIConstants.leadingInset)
        leftStatusImageView.pinCenterY(to: avatarImageView)
        leftStatusWidthConstraint = leftStatusImageView.setWidth(0)
        leftStatusImageView.setHeight(UIConstants.statusSymbolSize)

        avatarLeadingConstraintToContent = avatarImageView.pinLeft(
            to: contentView.leadingAnchor,
            UIConstants.leadingInset
        )
        avatarLeadingConstraintToStatus = avatarImageView.pinLeft(
            to: leftStatusImageView.trailingAnchor,
            UIConstants.statusToAvatarSpacing
        )
        avatarLeadingConstraintToStatus?.isActive = false

        avatarImageView.pinTop(to: contentView.topAnchor, 0)
        avatarImageView.pinBottom(to: contentView.bottomAnchor, 10)
        avatarImageView.setWidth(44)
        avatarImageView.setHeight(44)

        chevronImageView.pinRight(to: contentView.trailingAnchor, 24)
        chevronImageView.pinCenterY(to: avatarImageView)
        chevronWidthConstraint = chevronImageView.setWidth(UIConstants.chevronSymbolSize)
        chevronImageView.setHeight(UIConstants.chevronSymbolSize)

        textStackView.pinLeft(to: avatarImageView.trailingAnchor, 12)
        textStackView.pinCenterY(to: avatarImageView)
        textStackView.pinRight(to: chevronImageView.leadingAnchor, 12, .lsOE)
    }

    private func applyLeftStatusIcon(_ icon: QuizParticipantsOverviewModels.LeftStatusIcon?) {
        guard let icon else {
            leftStatusImageView.isHidden = true
            leftStatusWidthConstraint?.constant = 0
            avatarLeadingConstraintToContent?.isActive = true
            avatarLeadingConstraintToStatus?.isActive = false
            return
        }

        let symbolName: String
        let tintColor: UIColor
        switch icon {
        case .pendingReview:
            symbolName = "clock.fill"
            tintColor = .textSecondary

        case .reviewed:
            symbolName = "checkmark.seal.fill"
            tintColor = .accentPrimary
        }

        let configuration = UIImage.SymbolConfiguration(pointSize: UIConstants.statusSymbolSize, weight: .regular)
        leftStatusImageView.image = UIImage(systemName: symbolName, withConfiguration: configuration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)

        leftStatusImageView.isHidden = false
        leftStatusWidthConstraint?.constant = UIConstants.statusSymbolSize
        avatarLeadingConstraintToContent?.isActive = false
        avatarLeadingConstraintToStatus?.isActive = true
    }

    private func applyChevronVisibility(_ isVisible: Bool) {
        chevronImageView.isHidden = isVisible == false
        chevronWidthConstraint?.constant = isVisible ? UIConstants.chevronSymbolSize : 0
    }

    private func applyDimmedState(_ isDimmed: Bool) {
        let alpha: CGFloat = isDimmed ? 0.6 : 1
        avatarImageView.alpha = alpha
        nameLabel.alpha = alpha
        emailLabel.alpha = alpha
        leftStatusImageView.alpha = alpha
        chevronImageView.alpha = alpha
    }
}
