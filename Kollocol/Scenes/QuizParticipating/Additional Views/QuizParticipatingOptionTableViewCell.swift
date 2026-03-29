//
//  QuizParticipatingOptionTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingOptionTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let markControl = AnswerOptionMarkControl()

    private let optionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .textSecondary
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private let optionCounterLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private let tapButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingOptionTableViewCell"

    // MARK: - Properties
    var onTap: (() -> Void)?

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
    func configure(with option: QuizParticipatingModels.OptionViewData) {
        optionLabel.text = option.text
        optionCounterLabel.isHidden = option.isAnswersCountVisible == false
        if option.isAnswersCountVisible {
            optionCounterLabel.attributedText = makeOptionCounterAttributedText(count: option.answersCount)
        } else {
            optionCounterLabel.attributedText = nil
        }

        markControl.apply(
            configuration: .init(
                kind: option.kind,
                size: .regular,
                visualState: .neutral,
                isSelected: option.isSelected
            )
        )

        tapButton.isEnabled = option.isEnabled
        contentView.alpha = 1
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        optionCounterLabel.setContentHuggingPriority(.required, for: .horizontal)
        optionCounterLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(markControl)
        markControl.pinLeft(to: contentView.leadingAnchor, 28)
        markControl.pinTop(to: contentView.topAnchor, 0)

        contentView.addSubview(optionLabel)
        contentView.addSubview(optionCounterLabel)

        optionCounterLabel.pinTop(to: contentView.topAnchor, 0)
        optionCounterLabel.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        optionLabel.pinLeft(to: markControl.trailingAnchor, 12)
        optionLabel.pinRight(to: optionCounterLabel.leadingAnchor, 12)
        optionLabel.pinTop(to: contentView.topAnchor, 0)
        optionLabel.pinBottom(to: contentView.bottomAnchor, 20)

        contentView.addSubview(tapButton)
        tapButton.pin(to: contentView)
        tapButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    private func makeOptionCounterAttributedText(count: Int) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.textPrimary
        ]

        let attributedText = NSMutableAttributedString()

        let imageAttachment = NSTextAttachment()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        if let iconImage = UIImage(systemName: "person.2.fill", withConfiguration: imageConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal) {
            imageAttachment.image = iconImage
            imageAttachment.bounds = CGRect(
                x: 0,
                y: -2,
                width: iconImage.size.width,
                height: iconImage.size.height
            )
            attributedText.append(NSAttributedString(attachment: imageAttachment))
            attributedText.append(NSAttributedString(string: " "))
        }

        attributedText.append(
            NSAttributedString(
                string: "\(count)",
                attributes: textAttributes
            )
        )
        return attributedText
    }

    // MARK: - Actions
    @objc
    private func handleTap() {
        onTap?()
    }
}
