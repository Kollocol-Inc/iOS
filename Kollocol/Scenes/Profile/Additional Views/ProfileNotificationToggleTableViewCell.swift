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
        stack.spacing = 8
        return stack
    }()

    private let iconLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .textPrimary
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
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
    private enum UIConstants {
        static let iconSlotWidth: CGFloat = 34
    }

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
        iconLabel.attributedText = nil
    }

    // MARK: - Methods
    func configure(
        title: String,
        leadingIconSystemName: String? = nil,
        isOn: Bool,
        isEnabled: Bool = true
    ) {
        titleLabel.text = title
        applyLeadingIcon(systemName: leadingIconSystemName)
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

        horizontalStackView.addArrangedSubview(iconLabel)
        iconLabel.setWidth(UIConstants.iconSlotWidth)
        horizontalStackView.addArrangedSubview(titleLabel)
        horizontalStackView.addArrangedSubview(spacerView)
        horizontalStackView.addArrangedSubview(toggleSwitch)

        toggleSwitch.addTarget(self, action: #selector(handleToggleChanged), for: .valueChanged)
    }

    private func applyLeadingIcon(systemName: String?) {
        guard let systemName else {
            iconLabel.attributedText = nil
            return
        }

        iconLabel.attributedText = makeIconAttachment(
            systemName: systemName,
            tintColor: .textPrimary
        )
    }

    private func makeIconAttachment(systemName: String, tintColor: UIColor) -> NSAttributedString {
        let attachment = NSTextAttachment()
        let configuration = UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)
        attachment.image = UIImage(systemName: systemName, withConfiguration: configuration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)
        return NSAttributedString(attachment: attachment)
    }

    // MARK: - Actions
    @objc
    private func handleToggleChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }
}
