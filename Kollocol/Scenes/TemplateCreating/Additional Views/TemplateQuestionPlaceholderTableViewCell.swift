//
//  TemplateQuestionPlaceholderTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class TemplateQuestionPlaceholderTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let placeholderView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionPlaceholderTableViewCell"

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
    func configure(index: Int) {
        titleLabel.text = "Вопрос \(index + 1)"
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(placeholderView)
        placeholderView.pinTop(to: contentView.topAnchor, 8)
        placeholderView.pinBottom(to: contentView.bottomAnchor, 8)
        placeholderView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        placeholderView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        placeholderView.addSubview(titleLabel)
        titleLabel.pinLeft(to: placeholderView.leadingAnchor, 16)
        titleLabel.pinCenterY(to: placeholderView.centerYAnchor)
        titleLabel.pinRight(to: placeholderView.trailingAnchor, 16)
    }
}
