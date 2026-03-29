//
//  QuizParticipatingQuestionTextTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingQuestionTextTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 0
        label.textAlignment = .left
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

    // MARK: - Methods
    func configure(text: String) {
        questionLabel.text = text
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(questionLabel)
        questionLabel.pinTop(to: contentView.topAnchor, 0)
        questionLabel.pinLeft(to: contentView.leadingAnchor, 16)
        questionLabel.pinRight(to: contentView.trailingAnchor, 16)
        questionLabel.pinBottom(to: contentView.bottomAnchor, 20)
    }
}
