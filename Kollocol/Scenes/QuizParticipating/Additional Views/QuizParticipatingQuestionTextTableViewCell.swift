//
//  QuizParticipatingQuestionTextTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingQuestionTextTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let protectedQuestionContainer = ScreenshotProtectedContainerView()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .vertical)
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingQuestionTextTableViewCell"

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreferredMaxLayoutWidthIfNeeded()
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        let fallbackWidth = UIScreen.main.bounds.width
        let fittingWidth = targetSize.width > 0 ? targetSize.width : fallbackWidth
        let availableTextWidth = max(0, fittingWidth - 48)

        let textHeight = questionLabel.sizeThatFits(
            CGSize(width: availableTextWidth, height: .greatestFiniteMagnitude)
        ).height

        return CGSize(width: fittingWidth, height: ceil(textHeight + 20))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        questionLabel.alpha = 1
        protectedQuestionContainer.setSecureRenderingEnabled(false)
    }

    // MARK: - Methods
    func configure(
        text: String,
        isSensitiveTextHidden: Bool = false,
        isScreenshotProtectionEnabled: Bool = false
    ) {
        questionLabel.text = text
        protectedQuestionContainer.setSecureRenderingEnabled(isScreenshotProtectionEnabled)
        setSensitiveTextHidden(isSensitiveTextHidden)
        setNeedsLayout()
    }

    func setSensitiveTextHidden(_ isHidden: Bool) {
        questionLabel.alpha = isHidden ? 0 : 1
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(protectedQuestionContainer)
        protectedQuestionContainer.pinTop(to: contentView.topAnchor, 0)
        protectedQuestionContainer.pinLeft(to: contentView.leadingAnchor, 24)
        protectedQuestionContainer.pinRight(to: contentView.trailingAnchor, 24)
        protectedQuestionContainer.pinBottom(to: contentView.bottomAnchor, 20)

        protectedQuestionContainer.contentView.addSubview(questionLabel)
        questionLabel.pin(to: protectedQuestionContainer.contentView)
    }

    private func updatePreferredMaxLayoutWidthIfNeeded() {
        contentView.layoutIfNeeded()
        let targetWidth = protectedQuestionContainer.contentView.bounds.width
        guard targetWidth > 0 else { return }

        if abs(questionLabel.preferredMaxLayoutWidth - targetWidth) > 0.5 {
            questionLabel.preferredMaxLayoutWidth = targetWidth
            questionLabel.setNeedsLayout()
        }
    }
}
