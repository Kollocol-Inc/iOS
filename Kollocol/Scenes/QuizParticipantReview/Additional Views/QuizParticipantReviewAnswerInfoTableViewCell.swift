//
//  QuizParticipantReviewAnswerInfoTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit
import SwiftUI
import Shimmer

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

    private let shimmerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantReviewAnswerInfoTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let badgeLeadingInset: CGFloat = 18
        static let badgeTopInset: CGFloat = 8
        static let loadingToTextSpacing: CGFloat = 4
        static let loadingSize: CGFloat = 10
        static let answerTopInset: CGFloat = 8
        static let answerBottomInset: CGFloat = 12
        static let symbolPointSize: CGFloat = 8
        static let containerBottomInset: CGFloat = 12
    }

    // MARK: - Properties
    private var badgeLeadingConstraint: NSLayoutConstraint?
    private var badgeLeadingToLoaderConstraint: NSLayoutConstraint?
    private var shimmerHostingController: UIHostingController<AIThinkingShimmerTextView>?

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
        answerLabel.text = nil
        answerLabel.isHidden = false
        shimmerContainerView.isHidden = true
        shimmerHostingController?.rootView = AIThinkingShimmerTextView(text: "")
        badgeLeadingConstraint?.isActive = true
        badgeLeadingToLoaderConstraint?.isActive = false
    }

    // MARK: - Methods
    func configure(with viewData: QuizParticipantReviewModels.AnswerInfoViewData) {
        switch viewData.badge {
        case .correctAnswer:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            badgeLeadingConstraint?.isActive = true
            badgeLeadingToLoaderConstraint?.isActive = false
            badgeLabel.attributedText = makeBadgeAttributedText(
                systemImageName: "checkmark",
                text: "correctAnswer".localized
            )
            showPlainAnswer(text: viewData.text)

        case .ai:
            loadingIndicator.stopAnimating()
            loadingIndicator.isHidden = true
            badgeLeadingConstraint?.isActive = true
            badgeLeadingToLoaderConstraint?.isActive = false
            badgeLabel.attributedText = makeBadgeAttributedText(
                systemImageName: "sparkles",
                text: "ai".localized
            )
            showPlainAnswer(text: viewData.text)

        case .aiLoading:
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
            badgeLeadingConstraint?.isActive = false
            badgeLeadingToLoaderConstraint?.isActive = true
            badgeLabel.attributedText = nil
            badgeLabel.text = "ai".localized
            showShimmeringAnswer(text: viewData.text)
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
        loadingIndicator.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        loadingIndicator.setWidth(UIConstants.loadingSize)
        loadingIndicator.setHeight(UIConstants.loadingSize)

        containerView.addSubview(badgeLabel)
        badgeLabel.pinTop(to: containerView.topAnchor, UIConstants.badgeTopInset)
        badgeLeadingConstraint = badgeLabel.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        badgeLeadingToLoaderConstraint = badgeLabel.pinLeft(
            to: loadingIndicator.trailingAnchor,
            UIConstants.loadingToTextSpacing
        )
        badgeLeadingToLoaderConstraint?.isActive = false
        badgeLabel.pinRight(to: containerView.trailingAnchor, UIConstants.badgeLeadingInset)
        loadingIndicator.pinCenterY(to: badgeLabel.centerYAnchor)

        containerView.addSubview(answerLabel)
        answerLabel.pinTop(to: badgeLabel.bottomAnchor, UIConstants.answerTopInset)
        answerLabel.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        answerLabel.pinRight(to: containerView.trailingAnchor, UIConstants.badgeLeadingInset)
        answerLabel.pinBottom(to: containerView.bottomAnchor, UIConstants.answerBottomInset)

        containerView.addSubview(shimmerContainerView)
        shimmerContainerView.pinTop(to: badgeLabel.bottomAnchor, UIConstants.answerTopInset)
        shimmerContainerView.pinLeft(to: containerView.leadingAnchor, UIConstants.badgeLeadingInset)
        shimmerContainerView.pinRight(to: containerView.trailingAnchor, UIConstants.badgeLeadingInset)
        shimmerContainerView.pinBottom(to: containerView.bottomAnchor, UIConstants.answerBottomInset)

        configureShimmerView()
    }

    private func configureShimmerView() {
        guard shimmerHostingController == nil else {
            return
        }

        let hostingController = UIHostingController(
            rootView: AIThinkingShimmerTextView(text: "")
        )
        hostingController.view.backgroundColor = .clear

        shimmerContainerView.addSubview(hostingController.view)
        hostingController.view.pin(to: shimmerContainerView)

        shimmerHostingController = hostingController
    }

    private func showPlainAnswer(text: String) {
        answerLabel.text = text
        answerLabel.isHidden = false
        shimmerContainerView.isHidden = true
    }

    private func showShimmeringAnswer(text: String) {
        shimmerHostingController?.rootView = AIThinkingShimmerTextView(text: text)
        answerLabel.isHidden = true
        shimmerContainerView.isHidden = false
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

private struct AIThinkingShimmerTextView: View {
    // MARK: - Properties
    let text: String

    // MARK: - Body
    var body: some View {
        Text(text)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(Color(uiColor: .textSecondary))
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.layoutDirection, .leftToRight)
            .shimmering(
                active: true,
                animation: .linear(duration: 1.2).repeatForever(autoreverses: false)
            )
    }
}
