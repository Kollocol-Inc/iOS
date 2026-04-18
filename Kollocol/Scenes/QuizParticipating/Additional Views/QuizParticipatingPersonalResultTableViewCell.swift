//
//  QuizParticipatingPersonalResultTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 29.03.2026.
//

import UIKit

final class QuizParticipatingPersonalResultTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 29
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        view.clipsToBounds = false
        return view
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let placeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .accentPrimary
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingPersonalResultTableViewCell"

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
    func configure(with viewData: QuizParticipatingModels.PersonalResultViewData) {
        placeLabel.attributedText = makePlaceAttributedText(place: viewData.place)
        scoreLabel.text = "\(viewData.score)"
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.masksToBounds = false

        contentView.addSubview(cardView)
        cardView.pinTop(to: contentView.topAnchor, 16)
        cardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        cardView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        cardView.pinBottom(to: contentView.bottomAnchor, 16)
        cardView.setHeight(64)

        cardView.addSubview(contentStackView)
        contentStackView.pinLeft(to: cardView.leadingAnchor, 24)
        contentStackView.pinRight(to: cardView.trailingAnchor, 24)
        contentStackView.pinCenterY(to: cardView)

        contentStackView.addArrangedSubview(placeLabel)
        contentStackView.addArrangedSubview(scoreLabel)

        scoreLabel.setContentHuggingPriority(.required, for: .horizontal)
        scoreLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func makePlaceAttributedText(place: Int) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(
            string: "Ваше место: ",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                .foregroundColor: UIColor.textPrimary
            ]
        )

        attributedText.append(
            NSAttributedString(
                string: "\(place)",
                attributes: [
                    .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                    .foregroundColor: UIColor.accentPrimary
                ]
            )
        )

        if let medalColor = medalColor(for: place) {
            attributedText.append(
                NSAttributedString(
                    string: " ",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 17, weight: .medium),
                        .foregroundColor: UIColor.textPrimary
                    ]
                )
            )

            let imageAttachment = NSTextAttachment()
            let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
            imageAttachment.image = UIImage(systemName: "medal.fill", withConfiguration: imageConfiguration)?
                .withTintColor(medalColor, renderingMode: .alwaysOriginal)

            attributedText.append(NSAttributedString(attachment: imageAttachment))
        }

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
