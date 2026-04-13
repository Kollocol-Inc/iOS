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

    private let valueButton: UIButton = {
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.tintColor = .accentPrimary
        button.semanticContentAttribute = .forceRightToLeft
        button.contentHorizontalAlignment = .right
        return button
    }()

    // MARK: - Constants
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
        valueButton.menu = nil
    }

    // MARK: - Methods
    func configure(
        title: String,
        options: [Option],
        selectedOptionID: String,
        isEnabled: Bool = true
    ) {
        titleLabel.text = title
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
}
