//
//  QuizParticipantsOverviewReviewHeaderTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantsOverviewReviewHeaderTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.text = "Участники"
        return label
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "QuizParticipantsOverviewReviewHeaderTableViewCell"

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
    func configure(title: String, totalCount: Int, reviewedCount: Int) {
        titleLabel.text = title
        summaryLabel.attributedText = makeSummaryAttributedText(
            totalCount: totalCount,
            reviewedCount: reviewedCount
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(titleLabel)
        contentView.addSubview(summaryLabel)

        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        titleLabel.pinTop(to: contentView.topAnchor, 12)

        summaryLabel.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        summaryLabel.pinCenterY(to: titleLabel)
        summaryLabel.pinLeft(to: titleLabel.trailingAnchor, 12, .grOE)
    }

    private func makeSummaryAttributedText(totalCount: Int, reviewedCount: Int) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .medium),
            .foregroundColor: UIColor.textPrimary
        ]

        let result = NSMutableAttributedString(
            string: "\(totalCount) ",
            attributes: textAttributes
        )

        result.append(makeIconAttachment(systemName: "person.fill", tintColor: .accentPrimary))
        result.append(NSAttributedString(string: " • ", attributes: textAttributes))
        result.append(NSAttributedString(string: "\(reviewedCount) ", attributes: textAttributes))
        result.append(makeIconAttachment(systemName: "checkmark.seal.fill", tintColor: .accentPrimary))

        return result
    }

    private func makeIconAttachment(systemName: String, tintColor: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        attachment.image = UIImage(systemName: systemName, withConfiguration: configuration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)
        return NSAttributedString(attachment: attachment)
    }
}
