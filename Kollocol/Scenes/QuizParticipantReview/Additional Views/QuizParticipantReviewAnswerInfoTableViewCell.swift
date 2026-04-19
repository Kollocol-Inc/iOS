//
//  QuizParticipantReviewAnswerInfoTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantReviewAnswerInfoTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .dividerPrimary
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 8, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .left
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .textSecondary
        indicator.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        indicator.isHidden = true
        return indicator
    }()

    private let answerLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = .textSecondary
        label.textAlignment = .left
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantReviewAnswerInfoTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let badgeLeadingInset: CGFloat = 18
        static let badgeTopInset: CGFloat = 8
        static let loadingToTextSpacing: CGFloat = 4
        static let answerTopInset: CGFloat = 8
        static let answerBottomInset: CGFloat = 12
        static let symbolPointSize: CGFloat = 8
        static let containerBottomInset: CGFloat = 12
    }

    // MARK: - Properties
    private var badgeLeadingConstraint: NSLayoutConstraint?
    private var badgeLeadingToLoaderConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        badgeLabel.attributedText = nil
        badgeLabel.text = nil
        badgeLeadingConstraint?.isActive = true
        badgeLeadingToLoaderConstraint?.isActive = false
    }

    // MARK: - Methods
    func configure(with viewData: QuizParticipantReviewModels.AnswerInfoViewData) {
        answerLabel.text = viewData.text

        switch viewData.badge {
        case .correctAnswer:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            badgeLeadingConstraint?.isActive = true
            badgeLeadingToLoaderConstraint?.isActive = false
            badgeLabel.attributedText = makeBadgeAttributedText(
                systemImageName: "checkmark",
                text: "Верный ответ"
            )

        case .ai:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            badgeLeadingConstraint?.isActive = true
            badgeLeadingToLoaderConstraint?.isActive = false
            badgeLabel.attributedText = makeBadgeAttributedText(
                systemImageName: "sparkles",
                text: "ИИ"
            )

        case .aiLoading:
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            badgeLeadingConstraint?.isActive = false
            badgeLeadingToLoaderConstraint?.isActive = true
            badgeLabel.attributedText = nil
            badgeLabel.text = "ИИ"
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.pinTop(to: contentView.topAnchor)
        containerView.pinBottom(to: contentView.bottomAnchor, UIConstants.containerBottomInset)
        containerView.pinLeft(to: contentView.leadingAnchor, UIConstants.horizontalInset)
        containerView.pinRight(to: contentView.trailingAnchor, UIConstants.horizontalInset)

        containerView.addSubview(loadingIndicator)
        loadingIndicator.pinTop(to: containerView.topAnchor, UIConstants.badgeTopInset)
        loadingIndicator.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        loadingIndicator.setWidth(12)
        loadingIndicator.setHeight(12)

        containerView.addSubview(badgeLabel)
        badgeLabel.pinTop(to: containerView.topAnchor, UIConstants.badgeTopInset)
        badgeLeadingConstraint = badgeLabel.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        badgeLeadingToLoaderConstraint = badgeLabel.pinLeft(
            to: loadingIndicator.trailingAnchor,
            UIConstants.loadingToTextSpacing
        )
        badgeLeadingToLoaderConstraint?.isActive = false
        badgeLabel.pinRight(to: containerView.trailingAnchor, UIConstants.badgeLeadingInset)

        containerView.addSubview(answerLabel)
        answerLabel.pinTop(to: badgeLabel.bottomAnchor, UIConstants.answerTopInset)
        answerLabel.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        answerLabel.pinRight(to: containerView.trailingAnchor, UIConstants.badgeLeadingInset)
        answerLabel.pinBottom(to: containerView.bottomAnchor, UIConstants.answerBottomInset)
    }

    private func makeBadgeAttributedText(systemImageName: String, text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        if let image = badgeSymbolImage(systemImageName: systemImageName) {
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = image
            result.append(NSAttributedString(attachment: imageAttachment))
            result.append(
                NSAttributedString(
                    string: " ",
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                        .foregroundColor: UIColor.textSecondary
                    ]
                )
            )
        }

        result.append(
            NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                    .foregroundColor: UIColor.textSecondary
                ]
            )
        )

        return result
    }

    private func badgeSymbolImage(systemImageName: String) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: UIConstants.symbolPointSize, weight: .regular)
        )
        return UIImage(systemName: systemImageName, withConfiguration: configuration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
    }
}
