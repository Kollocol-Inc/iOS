//
//  QuizParticipatingQuestionInfoTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingQuestionInfoTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let horizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 12
        return stackView
    }()

    private let questionIndexPillView = QuizParticipatingInfoPillView()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private let timerPillView = QuizParticipatingInfoPillView()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingQuestionInfoTableViewCell"

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
    func configure(with viewData: QuizParticipatingModels.QuestionInfoViewData) {
        questionIndexPillView.configure(
            iconName: "questionmark.bubble.fill",
            text: "\(viewData.questionNumber)/\(viewData.totalQuestions)",
            tintColor: .textWhite
        )

        scoreLabel.text = String(
            format: "questionScoreShortFormat".localized,
            viewData.maxScore
        )

        let isCritical = viewData.remainingSeconds < 10
        let timerTextColor: UIColor = isCritical ? .backgroundRedSecondary : .textWhite
        timerPillView.configure(
            iconName: "clock.fill",
            text: formatTime(viewData.remainingSeconds),
            tintColor: timerTextColor
        )
        timerPillView.alpha = viewData.isTimerVisible ? 1 : 0
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(horizontalStackView)
        horizontalStackView.pinTop(to: contentView.topAnchor, 14)
        horizontalStackView.pinLeft(to: contentView.leadingAnchor, 24)
        horizontalStackView.pinRight(to: contentView.trailingAnchor, 24)
        horizontalStackView.pinBottom(to: contentView.bottomAnchor, 10)

        horizontalStackView.addArrangedSubview(questionIndexPillView)
        questionIndexPillView.setWidth(86)
        questionIndexPillView.setHeight(42)

        horizontalStackView.addArrangedSubview(scoreLabel)

        horizontalStackView.addArrangedSubview(timerPillView)
        timerPillView.setWidth(86)
        timerPillView.setHeight(42)
    }

    private func formatTime(_ seconds: Int) -> String {
        let normalizedSeconds = max(0, seconds)
        let minutes = normalizedSeconds / 60
        let secondsPart = normalizedSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsPart)
    }
}
