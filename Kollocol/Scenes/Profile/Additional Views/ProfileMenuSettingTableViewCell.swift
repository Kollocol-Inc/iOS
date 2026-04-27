//
//  ProfileMenuSettingTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 12.04.2026.
//

import UIKit

final class ProfileMenuSettingTableViewCell: UITableViewCell {
    // MARK: - Typealias
    struct Option: Equatable {
        let id: String
        let title: String
    }

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

    private let valueButton: UIButton = {
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.tintColor = .accentPrimary
        button.semanticContentAttribute = .forceRightToLeft
        button.contentHorizontalAlignment = .right
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let iconSlotWidth: CGFloat = 34
    }

    static let reuseIdentifier = "ProfileMenuSettingTableViewCell"

    // MARK: - Properties
    var onOptionSelected: ((String) -> Void)?

    private var options: [Option] = []
    private var selectedOptionID = ""

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
        onOptionSelected = nil
        options = []
        selectedOptionID = ""
        iconLabel.attributedText = nil
        titleLabel.text = nil
        valueButton.menu = nil
    }

    // MARK: - Methods
    func configure(
        title: String,
        options: [Option],
        selectedOptionID: String,
        leadingIconSystemName: String? = nil,
        isEnabled: Bool = true
    ) {
        titleLabel.text = title
        applyLeadingIcon(systemName: leadingIconSystemName)
        self.options = options
        self.selectedOptionID = selectedOptionID
        valueButton.isEnabled = isEnabled

        applyValueButtonContent()
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
        horizontalStackView.addArrangedSubview(valueButton)
    }

    private func applyValueButtonContent() {
        let resolvedOption = options.first(where: { $0.id == selectedOptionID }) ?? options.first
        let selectedTitle = resolvedOption?.title ?? ""

        let actions = options.map { option in
            UIAction(
                title: option.title,
                state: option.id == selectedOptionID ? .on : .off
            ) { [weak self] _ in
                guard let self, self.selectedOptionID != option.id else { return }
                self.selectedOptionID = option.id
                self.applyValueButtonContent()
                self.onOptionSelected?(option.id)
            }
        }

        valueButton.menu = UIMenu(children: actions)
        valueButton.setAttributedTitle(
            NSAttributedString(
                string: selectedTitle,
                attributes: [
                    .foregroundColor: UIColor.accentPrimary,
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            ),
            for: .normal
        )

        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
        let chevronImage = UIImage(
            systemName: "chevron.up.chevron.down",
            withConfiguration: symbolConfiguration
        )?.withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        valueButton.setImage(chevronImage, for: .normal)
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
}
