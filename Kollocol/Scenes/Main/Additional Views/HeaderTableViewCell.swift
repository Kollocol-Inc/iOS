//
//  HeaderTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.02.2026.
//

import UIKit

final class HeaderTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "HeaderTableViewCell"

    // MARK: - UI Components
    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
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
    func configure(title: String) {
        label.text = title
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()

        contentView.layer.masksToBounds = false
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(label)
        label.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        label.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        label.pinTop(to: contentView.topAnchor, 12)
    }
}
