//
//  QuizParticipantReviewOptionTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantReviewOptionTableViewCell: UITableViewCell {
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

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantReviewOptionTableViewCell"

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
        markControl.stopAnimating()
    }

    // MARK: - Methods
    func configure(with viewData: QuizParticipantReviewModels.OptionRowViewData) {
        optionLabel.text = viewData.text
        optionLabel.textColor = textColor(for: viewData.textStyle)

        markControl.apply(
            configuration: .init(
                kind: viewData.kind,
                size: .regular,
                visualState: viewData.visualState,
                isSelected: viewData.isSelected
            )
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(markControl)
        markControl.pinLeft(to: contentView.leadingAnchor, 28)
        markControl.pinTop(to: contentView.topAnchor, 0)

        contentView.addSubview(optionLabel)
        optionLabel.pinLeft(to: markControl.trailingAnchor, 12)
        optionLabel.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        optionLabel.pinTop(to: contentView.topAnchor, 0)
        optionLabel.pinBottom(to: contentView.bottomAnchor, 20)
    }

    private func textColor(for style: QuizParticipantReviewModels.OptionTextStyle) -> UIColor {
        switch style {
        case .neutral:
            return .textSecondary
        case .correct:
            return .backgroundGreen
        case .incorrect:
            return .backgroundRedSecondary
        }
    }
}
