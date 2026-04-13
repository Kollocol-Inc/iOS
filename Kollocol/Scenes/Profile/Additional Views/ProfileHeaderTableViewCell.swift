//
//  ProfileHeaderTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import UIKit

final class ProfileHeaderTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .dividerPrimary
        view.layer.cornerRadius = 4
        view.layer.cornerCurve = .continuous
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = .systemFont(ofSize: 10, weight: .semibold)
        label.textAlignment = .left
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "ProfileHeaderTableViewCell"

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
        titleLabel.text = text
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.pinTop(to: contentView.topAnchor, 14)
        containerView.pinBottom(to: contentView.bottomAnchor, 4)
        containerView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        containerView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        containerView.setHeight(20)

        containerView.addSubview(titleLabel)
        titleLabel.pinCenterY(to: containerView.centerYAnchor)
        titleLabel.pinLeft(to: containerView.leadingAnchor, 8)
        titleLabel.pinRight(to: containerView.trailingAnchor, 8)
    }
}
