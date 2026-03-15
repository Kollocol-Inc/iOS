//
//  TemplateSettingsTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import UIKit

final class TemplateSettingsTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let quizTypeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Тип квиза"
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let quizTypeInfoButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 11, weight: .semibold)
        )
        let image = UIImage(
            systemName: "info.circle",
            withConfiguration: symbolConfiguration
        )?.withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let quizTypeButton: UIButton = {
        let button = UIButton(type: .system)
        button.showsMenuAsPrimaryAction = true
        button.tintColor = .accentPrimary
        return button
    }()

    private let randomOrderTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Случайный порядок"
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let randomOrderSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = .accentPrimary
        return control
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateSettingsTableViewCell"

    // MARK: - Properties
    var onQuizTypeChanged: ((QuizType) -> Void)?
    var onRandomOrderChanged: ((Bool) -> Void)?
    var onQuizTypeInfoTap: ((QuizType) -> Void)?

    private var quizType: QuizType = .async
    private var isLoading = false

    var selectedQuizType: QuizType {
        quizType
    }

    var isRandomOrderEnabled: Bool {
        randomOrderSwitch.isOn
    }

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
    func configure(
        quizType: QuizType,
        isRandomOrderEnabled: Bool,
        isLoading: Bool
    ) {
        self.quizType = quizType
        self.isLoading = isLoading
        randomOrderSwitch.isOn = isRandomOrderEnabled

        applyQuizType()
        applyInteractivity()
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
        configureActions()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(quizTypeTitleLabel)
        quizTypeTitleLabel.pinTop(to: contentView.topAnchor)
        quizTypeTitleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 32)

        contentView.addSubview(quizTypeButton)
        quizTypeButton.pinCenterY(to: quizTypeTitleLabel)
        quizTypeButton.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        contentView.addSubview(quizTypeInfoButton)
        quizTypeInfoButton.pinCenterY(to: quizTypeTitleLabel)
        quizTypeInfoButton.pinRight(to: quizTypeButton.leadingAnchor, 8)

        contentView.addSubview(randomOrderTitleLabel)
        randomOrderTitleLabel.pinTop(to: quizTypeTitleLabel.bottomAnchor, 16)
        randomOrderTitleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 32)
        randomOrderTitleLabel.pinBottom(to: contentView.bottomAnchor, 16)

        contentView.addSubview(randomOrderSwitch)
        randomOrderSwitch.pinCenterY(to: randomOrderTitleLabel)
        randomOrderSwitch.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }

    private func configureActions() {
        randomOrderSwitch.addTarget(self, action: #selector(handleRandomOrderChanged), for: .valueChanged)
        quizTypeInfoButton.addTarget(self, action: #selector(handleQuizTypeInfoTap), for: .touchUpInside)
    }

    private func applyQuizType() {
        let actionAsync = UIAction(
            title: QuizType.async.displayName,
            state: quizType == .async ? .on : .off
        ) { [weak self] _ in
            self?.setQuizType(.async)
        }

        let actionSync = UIAction(
            title: QuizType.sync.displayName,
            state: quizType == .sync ? .on : .off
        ) { [weak self] _ in
            self?.setQuizType(.sync)
        }

        quizTypeButton.menu = UIMenu(children: [actionAsync, actionSync])
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 13, weight: .semibold)
        )
        let chevronImage = UIImage(
            systemName: "chevron.up.chevron.down",
            withConfiguration: symbolConfiguration
        )?.withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        quizTypeButton.setAttributedTitle(
            NSAttributedString(
                string: abbreviatedDisplayName(for: quizType),
                attributes: [
                    .foregroundColor: UIColor.accentPrimary,
                    .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
                ]
            ),
            for: .normal
        )
        quizTypeButton.setImage(chevronImage, for: .normal)
        quizTypeButton.semanticContentAttribute = .forceRightToLeft
        quizTypeButton.contentHorizontalAlignment = .right
    }

    private func setQuizType(_ type: QuizType) {
        guard quizType != type else { return }
        quizType = type
        applyQuizType()
        applyRandomOrderAvailability(
            animated: true,
            notifyIfForcedOff: true
        )
        onQuizTypeChanged?(type)
    }

    private func applyInteractivity() {
        quizTypeInfoButton.isEnabled = !isLoading
        quizTypeButton.isEnabled = !isLoading
        applyRandomOrderAvailability(
            animated: false,
            notifyIfForcedOff: false
        )
    }

    private func applyRandomOrderAvailability(
        animated: Bool,
        notifyIfForcedOff: Bool
    ) {
        let isRandomOrderAvailable = quizType == .async
        let targetAlpha: CGFloat = isRandomOrderAvailable ? 1.0 : 0.5

        randomOrderTitleLabel.alpha = targetAlpha
        randomOrderSwitch.alpha = targetAlpha

        if isRandomOrderAvailable == false, randomOrderSwitch.isOn {
            randomOrderSwitch.setOn(false, animated: animated)
            if notifyIfForcedOff {
                onRandomOrderChanged?(false)
            }
        }

        randomOrderSwitch.isEnabled = isLoading == false && isRandomOrderAvailable
    }

    private func abbreviatedDisplayName(for quizType: QuizType) -> String {
        switch quizType {
        case .async:
            return "Асинх."
        case .sync:
            return "Синх."
        }
    }

    // MARK: - Actions
    @objc
    private func handleRandomOrderChanged() {
        guard quizType == .async else {
            randomOrderSwitch.setOn(false, animated: true)
            onRandomOrderChanged?(false)
            return
        }

        onRandomOrderChanged?(randomOrderSwitch.isOn)
    }

    @objc
    private func handleQuizTypeInfoTap() {
        onQuizTypeInfoTap?(quizType)
    }
}
