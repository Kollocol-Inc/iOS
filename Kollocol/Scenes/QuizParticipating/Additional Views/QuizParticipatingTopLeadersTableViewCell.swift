//
//  QuizParticipatingTopLeadersTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 29.03.2026.
//

import UIKit

final class QuizParticipatingTopLeadersTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .bottom
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()

    private let secondPlaceView = PodiumParticipantView(avatarSize: 60)
    private let firstPlaceView = PodiumParticipantView(avatarSize: 80)
    private let thirdPlaceView = PodiumParticipantView(avatarSize: 60)

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingTopLeadersTableViewCell"

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
    func configure(with leaders: [QuizParticipatingModels.FinalTopLeaderViewData]) {
        var leadersByRank: [Int: QuizParticipatingModels.FinalTopLeaderViewData] = [:]
        for leader in leaders {
            leadersByRank[leader.rank] = leader
        }

        secondPlaceView.configure(
            with: leadersByRank[2],
            medalColor: .backgroundSilver
        )
        firstPlaceView.configure(
            with: leadersByRank[1],
            medalColor: .backgroundGold
        )
        thirdPlaceView.configure(
            with: leadersByRank[3],
            medalColor: .backgroundBronze
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(horizontalStackView)
        horizontalStackView.pinTop(to: contentView.topAnchor, 0)
        horizontalStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        horizontalStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        horizontalStackView.pinBottom(to: contentView.bottomAnchor, 16)

        horizontalStackView.addArrangedSubview(secondPlaceView)
        horizontalStackView.addArrangedSubview(firstPlaceView)
        horizontalStackView.addArrangedSubview(thirdPlaceView)
    }
}

// MARK: - PodiumParticipantView
private final class PodiumParticipantView: UIView {
    // MARK: - UI Components
    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private let medalImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "avatarPlaceholder")
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .accentPrimary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Properties
    private let avatarSize: CGFloat

    // MARK: - Lifecycle
    init(avatarSize: CGFloat) {
        self.avatarSize = avatarSize
        super.init(frame: .zero)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(
        with leader: QuizParticipatingModels.FinalTopLeaderViewData?,
        medalColor: UIColor
    ) {
        guard let leader else {
            medalImageView.image = nil
            avatarImageView.image = nil
            nameLabel.text = nil
            scoreLabel.text = nil
            verticalStackView.alpha = 0
            return
        }

        let medalConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        medalImageView.image = UIImage(systemName: "medal.fill", withConfiguration: medalConfiguration)?
            .withTintColor(medalColor, renderingMode: .alwaysOriginal)

        avatarImageView.setImage(
            url: leader.participant.avatarURL,
            placeholder: UIImage(named: "avatarPlaceholder")
        )

        let participantName = [leader.participant.firstName, leader.participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        nameLabel.text = participantName.isEmpty ? "Участник" : participantName
        scoreLabel.text = "\(leader.score)"
        verticalStackView.alpha = 1
    }

    // MARK: - Private Methods
    private func configureUI() {
        addSubview(verticalStackView)
        verticalStackView.pinTop(to: topAnchor)
        verticalStackView.pinLeft(to: leadingAnchor)
        verticalStackView.pinRight(to: trailingAnchor)
        verticalStackView.pinBottom(to: bottomAnchor)

        verticalStackView.addArrangedSubview(medalImageView)
        verticalStackView.addArrangedSubview(avatarImageView)
        verticalStackView.addArrangedSubview(nameLabel)
        verticalStackView.addArrangedSubview(scoreLabel)

        medalImageView.setWidth(17)
        medalImageView.setHeight(17)

        avatarImageView.setWidth(avatarSize)
        avatarImageView.setHeight(avatarSize)
        avatarImageView.layer.cornerRadius = avatarSize / 2

        nameLabel.pinWidth(to: widthAnchor, 1, .lsOE)
        scoreLabel.pinWidth(to: widthAnchor, 1, .lsOE)
    }
}
