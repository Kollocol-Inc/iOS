//
//  QuizParticipatingFinalParticipantTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 29.03.2026.
//

import UIKit

final class QuizParticipatingFinalParticipantTableViewCell: UITableViewCell {
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

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
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

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = .accentPrimary
        label.numberOfLines = 1
        label.textAlignment = .right
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingFinalParticipantTableViewCell"

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
    func configure(with viewData: QuizParticipatingModels.FinalParticipantRowViewData) {
        let participant = viewData.participant

        let participantName = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        nameLabel.text = participantName.isEmpty ? "participant".localized : participantName

        let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emailLabel.text = email
        emailLabel.isHidden = email.isEmpty

        avatarImageView.setImage(
            url: participant.avatarURL,
            placeholder: UIImage(named: "avatarPlaceholder")
        )

        scoreLabel.text = "\(viewData.score)"
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(emailLabel)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(textStackView)
        contentView.addSubview(scoreLabel)

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
}
