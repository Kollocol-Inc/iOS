//
//  ProfileNotificationToggleTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import UIKit

final class ProfileNotificationToggleTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let horizontalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let spacerView = UIView()

    private let toggleSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = .accentPrimary
        return control
    }()

    // MARK: - Constants
    static let reuseIdentifier = "ProfileNotificationToggleTableViewCell"

    // MARK: - Properties
    var onToggleChanged: ((Bool) -> Void)?

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
        onToggleChanged = nil
    }

    // MARK: - Methods
    func configure(title: String, isOn: Bool, isEnabled: Bool = true) {
        titleLabel.text = title
        toggleSwitch.setOn(isOn, animated: false)
        toggleSwitch.isEnabled = isEnabled
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(horizontalStackView)
        horizontalStackView.pinTop(to: contentView.topAnchor, 8)
        horizontalStackView.pinBottom(to: contentView.bottomAnchor, 8)
        horizontalStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        horizontalStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        horizontalStackView.addArrangedSubview(titleLabel)
        horizontalStackView.addArrangedSubview(spacerView)
        horizontalStackView.addArrangedSubview(toggleSwitch)

        toggleSwitch.addTarget(self, action: #selector(handleToggleChanged), for: .valueChanged)
    }

    // MARK: - Actions
    @objc
    private func handleToggleChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }
}
