//
//  EmptyStateTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.03.2026.
//

import UIKit

final class EmptyStateTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "EmptyStateTableViewCell"

    // MARK: - UI Components
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

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
        messageLabel.text = text
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(messageLabel)
        messageLabel.pinTop(to: contentView.topAnchor, 4)
        messageLabel.pinBottom(to: contentView.bottomAnchor, 12)
        messageLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        messageLabel.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }
}
