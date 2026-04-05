//
//  QuizParticipatingOpenAnswerTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingOpenAnswerTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let answerTextView: StripedLoadingTextView = {
        let textView = StripedLoadingTextView()
        textView.backgroundColor = .dividerPrimary
        textView.layer.cornerRadius = 18
        textView.font = .systemFont(ofSize: 17, weight: .medium)
        textView.textColor = .textSecondary
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.clipsToBounds = true
        return textView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipatingOpenAnswerTableViewCell"

    // MARK: - Properties
    var onDidEndEditing: ((String) -> Void)?

    private var isUpdatingUI = false

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
        answerTextView.stopAnimating()
        onDidEndEditing = nil
    }

    // MARK: - Methods
    var currentText: String {
        answerTextView.text
    }

    func configure(text: String, isEditable: Bool, isLoading: Bool) {
        isUpdatingUI = true
        answerTextView.text = text

        if isLoading {
            answerTextView.isEditable = false
            answerTextView.isSelectable = false
            answerTextView.isScrollEnabled = true
            answerTextView.alpha = 1
            answerTextView.startAnimating()
        } else {
            answerTextView.stopAnimating()
            answerTextView.isEditable = isEditable
            answerTextView.isSelectable = isEditable
            answerTextView.isScrollEnabled = true
            answerTextView.isUserInteractionEnabled = isEditable
            answerTextView.alpha = isEditable ? 1 : 0.8
        }

        isUpdatingUI = false
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(answerTextView)
        answerTextView.pinTop(to: contentView.topAnchor, 0)
        answerTextView.pinLeft(to: contentView.leadingAnchor, 24)
        answerTextView.pinRight(to: contentView.trailingAnchor, 24)
        answerTextView.pinBottom(to: contentView.bottomAnchor, 20)
        answerTextView.setHeight(120)
        answerTextView.delegate = self
    }
}

// MARK: - UITextViewDelegate
extension QuizParticipatingOpenAnswerTableViewCell: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if isUpdatingUI {
            return
        }

        onDidEndEditing?(textView.text)
    }
}
