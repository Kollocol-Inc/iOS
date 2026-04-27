//
//  QuizParticipantReviewQuestionIndexCollectionViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantReviewQuestionIndexCollectionViewCell: UICollectionViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 18
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.dividerPrimary.cgColor
        view.backgroundColor = .clear
        return view
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 0
        return stackView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantReviewQuestionIndexCollectionViewCell"

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(with item: QuizParticipantReviewModels.QuestionSwitcherItemViewData) {
        numberLabel.text = "\(item.questionNumber)"
        scoreLabel.text = String(
            format: "questionScoreShortFormat".localized,
            item.maxScore
        )

        containerView.backgroundColor = item.hasFilledBackground ? .dividerPrimary : .clear

        switch item.borderStyle {
        case .neutral:
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor.dividerPrimary.cgColor

        case .correct:
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor.backgroundGreen.cgColor

        case .incorrect:
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor.backgroundRedSecondary.cgColor

        case .none:
            containerView.layer.borderWidth = 0
            containerView.layer.borderColor = UIColor.clear.cgColor

        case .selected:
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor.accentPrimary.cgColor
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.pin(to: contentView)

        containerView.addSubview(textStackView)
        textStackView.pinCenter(to: containerView)
        textStackView.addArrangedSubview(numberLabel)
        textStackView.addArrangedSubview(scoreLabel)
    }
}
