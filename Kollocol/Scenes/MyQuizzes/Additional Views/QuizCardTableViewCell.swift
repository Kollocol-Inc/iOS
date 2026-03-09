//
//  QuizCardTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 09.03.2026.
//

import UIKit

final class QuizCardTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let quizCardView = QuizCardView()

    // MARK: - Constants
    static let reuseIdentifier = "QuizCardTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let verticalInset: CGFloat = 0
    }

    // MARK: - Properties
    var onQuizTypeTap: ((QuizType) -> Void)?
    var onQuizStartTap: (() -> Void)?

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
        onQuizTypeTap = nil
        onQuizStartTap = nil
    }

    // MARK: - Methods
    func configure(with item: QuizInstanceViewData, isTemplate: Bool = false) {
        quizCardView.configure(with: item, isTemplate: isTemplate)
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
        configureActions()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(quizCardView)
        quizCardView.pinTop(to: contentView.topAnchor, UIConstants.verticalInset)
        quizCardView.pinBottom(to: contentView.bottomAnchor, UIConstants.verticalInset)
        quizCardView.pinLeft(to: contentView.leadingAnchor, UIConstants.horizontalInset)
        quizCardView.pinRight(to: contentView.trailingAnchor, UIConstants.horizontalInset)
    }

    private func configureActions() {
        quizCardView.onQuizTypeTap = { [weak self] quizType in
            self?.onQuizTypeTap?(quizType)
        }

        quizCardView.onQuizStartTap = { [weak self] in
            self?.onQuizStartTap?()
        }
    }
}
