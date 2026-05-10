//
//  ProfileDangerZoneButtonTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import UIKit

final class ProfileDangerZoneButtonTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.backgroundRedSecondary.cgColor
        button.setHeight(42)
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "ProfileDangerZoneButtonTableViewCell"

    private enum UIConstants {
        // ProfileHeaderTableViewCell uses bottom inset = 4 for its inner view.
        // Required visual spacing between that view and this button is 12 -> 12 - 4 = 8.
        static let topInset: CGFloat = 8
        static let horizontalInset: CGFloat = 24
        static let bottomInset: CGFloat = 0
        static let buttonHeight: CGFloat = 42
    }

    // MARK: - Properties
    var onTap: (() -> Void)?

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
        onTap = nil
    }

    // MARK: - Methods
    func configure(title: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        actionButton.setAttributedTitle(
            NSAttributedString(
                string: title,
                attributes: [
                    .foregroundColor: UIColor.backgroundRedSecondary,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(actionButton)
        actionButton.pinTop(to: contentView.topAnchor, UIConstants.topInset)
        actionButton.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.horizontalInset)
        actionButton.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.horizontalInset)
        actionButton.pinBottom(to: contentView.bottomAnchor, UIConstants.bottomInset)
        actionButton.setHeight(UIConstants.buttonHeight)

        actionButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc
    private func handleTap() {
        onTap?()
    }
}
