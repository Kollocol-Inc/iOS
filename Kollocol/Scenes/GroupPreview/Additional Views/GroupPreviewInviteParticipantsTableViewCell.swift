//
//  GroupPreviewInviteParticipantsTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import UIKit

final class GroupPreviewInviteParticipantsTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.tintColor = .textWhite
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "GroupPreviewInviteParticipantsTableViewCell"

    // MARK: - Properties
    private var action: (() -> Void)?

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
    func configure(title: String, action: @escaping () -> Void) {
        self.action = action
        button.setTitle(title, for: .normal)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(button)
        button.pinTop(to: contentView.topAnchor, 12)
        button.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        button.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        button.setHeight(42)

        button.addTarget(self, action: #selector(handleButtonTap), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc
    private func handleButtonTap() {
        action?()
    }
}
