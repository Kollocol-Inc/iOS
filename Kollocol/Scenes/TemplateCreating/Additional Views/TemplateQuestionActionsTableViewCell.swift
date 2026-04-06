//
//  TemplateQuestionActionsTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class TemplateQuestionActionsTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let addQuestionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setAttributedTitle(
            NSAttributedString(
                string: "Добавить вопрос",
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.titleLabel?.lineBreakMode = .byClipping
        button.setHeight(42)
        return button
    }()

    private let completeWithAIButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.textSecondary.cgColor
        button.setAttributedTitle(
            NSAttributedString(
                string: "Дополнить с ИИ",
                attributes: [
                    .foregroundColor: UIColor.textSecondary,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )

        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 14, weight: .semibold)
        )
        let image = UIImage(systemName: "wand.and.sparkles", withConfiguration: symbolConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.configuration = {
            var config = UIButton.Configuration.plain()
            config.imagePadding = 6
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)
            return config
        }()
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.titleLabel?.lineBreakMode = .byClipping
        button.setHeight(42)
        return button
    }()

    private let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        return stackView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionActionsTableViewCell"

    // MARK: - Properties
    var onAddQuestionTap: (() -> Void)?
    var onCompleteWithAITap: (() -> Void)?

    private var isAiButtonEnabled = true

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
        onAddQuestionTap = nil
        onCompleteWithAITap = nil
    }

    // MARK: - Methods
    func configure(isAiButtonEnabled: Bool) {
        self.isAiButtonEnabled = isAiButtonEnabled
        completeWithAIButton.isEnabled = isAiButtonEnabled
        completeWithAIButton.alpha = isAiButtonEnabled ? 1 : 0.6
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureActionsStackView()
        configureConstraints()
        configureActions()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureActionsStackView() {
        actionsStackView.addArrangedSubview(addQuestionButton)
        actionsStackView.addArrangedSubview(completeWithAIButton)
    }

    private func configureConstraints() {
        contentView.addSubview(actionsStackView)
        actionsStackView.pinTop(to: contentView.topAnchor, 10)
        actionsStackView.pinBottom(to: contentView.bottomAnchor, 16)
        actionsStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        actionsStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }

    private func configureActions() {
        addQuestionButton.addTarget(self, action: #selector(handleAddQuestionTap), for: .touchUpInside)
        completeWithAIButton.addTarget(self, action: #selector(handleCompleteWithAITap), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc
    private func handleAddQuestionTap() {
        onAddQuestionTap?()
    }

    @objc
    private func handleCompleteWithAITap() {
        onCompleteWithAITap?()
    }
}
