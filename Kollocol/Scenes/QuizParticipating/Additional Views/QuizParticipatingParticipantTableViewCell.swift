//
//  QuizParticipatingParticipantTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 29.03.2026.
//

import UIKit

final class QuizParticipatingParticipantTableViewCell: UITableViewCell {
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
        label.lineBreakMode = .byTruncatingTail
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

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingParticipantTableViewCell"

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
    func configure(with viewData: QuizParticipatingModels.ParticipantRowViewData) {
        let participant = viewData.participant

        let name = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        nameLabel.text = name.isEmpty ? "Участник" : name

        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailLabel.text = email
        emailLabel.isHidden = email.isEmpty

        avatarImageView.setImage(
            url: participant.avatarURL,
            placeholder: UIImage(named: "avatarPlaceholder")
        )

        scoreLabel.attributedText = makeScoreAttributedText(
            score: viewData.score,
            place: viewData.place
        )
        applyOnlineState(isOffline: viewData.isOffline)
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
        contentView.addSubview(scoreLabel)

        offlineStatusImageView.pinRight(to: avatarImageView.leadingAnchor, 4)
        offlineStatusImageView.pinCenterY(to: avatarImageView)
        offlineStatusImageView.setWidth(17)
        offlineStatusImageView.setHeight(17)

        avatarImageView.pinLeft(to: contentView.leadingAnchor, 28)
        avatarImageView.pinTop(to: contentView.topAnchor, 0)
        avatarImageView.pinBottom(to: contentView.bottomAnchor, 10)
        avatarImageView.setWidth(44)
        avatarImageView.setHeight(44)

        scoreLabel.pinRight(to: contentView.trailingAnchor, 24)
        scoreLabel.pinCenterY(to: avatarImageView)
        scoreLabel.setContentHuggingPriority(.required, for: .horizontal)
        scoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        textStackView.pinLeft(to: avatarImageView.trailingAnchor, 12)
        textStackView.pinCenterY(to: avatarImageView)
        textStackView.pinRight(to: scoreLabel.leadingAnchor, 12)
    }

    private func applyOnlineState(isOffline: Bool) {
        offlineStatusImageView.isHidden = isOffline == false
    }

    private func makeScoreAttributedText(score: Int, place: Int) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.accentPrimary
        ]

        guard score > 0 else {
            return NSAttributedString(
                string: "\(score)",
                attributes: textAttributes
            )
        }

        guard let medalColor = medalColor(for: place) else {
            return NSAttributedString(
                string: "\(score)",
                attributes: textAttributes
            )
        }

        let attributedText = NSMutableAttributedString()

        let imageAttachment = NSTextAttachment()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        imageAttachment.image = UIImage(systemName: "medal.fill", withConfiguration: imageConfiguration)?
            .withTintColor(medalColor, renderingMode: .alwaysOriginal)
        imageAttachment.bounds = CGRect(x: 0, y: -2, width: 17, height: 17)

        attributedText.append(NSAttributedString(attachment: imageAttachment))
        attributedText.append(
            NSAttributedString(
                string: " • \(score)",
                attributes: textAttributes
            )
        )

        return attributedText
    }

    private func medalColor(for place: Int) -> UIColor? {
        switch place {
        case 1:
            return .backgroundGold
        case 2:
            return .backgroundSilver
        case 3:
            return .backgroundBronze
        default:
            return nil
        }
    }
}
