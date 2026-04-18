//
//  QuizWaitingRoomParticipantsHeaderTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizWaitingRoomParticipantsHeaderTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.text = "Участники"
        return label
    }()

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizWaitingRoomParticipantsHeaderTableViewCell"

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
    func configure(count: Int) {
        configure(title: "Участники", count: count)
    }

    func configure(title: String, count: Int) {
        titleLabel.text = title
        counterLabel.attributedText = makeParticipantsCounterAttributedText(count: count)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(titleLabel)
        contentView.addSubview(counterLabel)

        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        titleLabel.pinTop(to: contentView.topAnchor, 12)

        counterLabel.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        counterLabel.pinCenterY(to: titleLabel)
        counterLabel.pinLeft(to: titleLabel.trailingAnchor, 12, .grOE)
    }

    private func makeParticipantsCounterAttributedText(count: Int) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor.textPrimary
        ]

        let attributedText = NSMutableAttributedString(
            string: "\(count) ",
            attributes: textAttributes
        )

        let imageAttachment = NSTextAttachment()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        imageAttachment.image = UIImage(systemName: "person.fill", withConfiguration: imageConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        attributedText.append(NSAttributedString(attachment: imageAttachment))
        return attributedText
    }
}
