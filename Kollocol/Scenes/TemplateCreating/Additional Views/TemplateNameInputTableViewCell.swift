//
//  TextInputTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import UIKit

final class TextInputTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleTextField: StripedLoadingTextField = {
        let field = StripedLoadingTextField()
        field.attributedPlaceholder = NSAttributedString(
            string: "Введите название",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
        field.clipsToBounds = true
        field.addPadding(left: 12)
        field.setHeight(38)
        return field
    }()

    private let rightActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .textPrimary
        button.setImage(
            UIImage(systemName: "wand.and.sparkles.inverse")?
                .withTintColor(.textPrimary, renderingMode: .alwaysOriginal),
            for: .normal
        )
        return button
    }()

    private let leftActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .textPrimary
        button.setImage(
            UIImage(systemName: "arrow.uturn.backward")?
                .withTintColor(.textPrimary, renderingMode: .alwaysOriginal),
            for: .normal
        )
        return button
    }()

    private let rightActionContainer: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 26))
    }()

    private let rightSpacerView: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TextInputTableViewCell"

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?
    var onRightActionTap: (() -> Void)?
    var onLeftActionTap: (() -> Void)?

    private var showsRightAction = false
    private var showsLeftAction = false

    var currentText: String? {
        titleTextField.text
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

    override func prepareForReuse() {
        super.prepareForReuse()
        onTextChanged = nil
        onRightActionTap = nil
        onLeftActionTap = nil
        showsRightAction = false
        showsLeftAction = false
        setRightAccessoryVisible(false)
        titleTextField.stopAnimating()
    }

    // MARK: - Methods
    func configure(
        title: String?,
        placeholder: String,
        isLoading: Bool,
        showsRightAction: Bool = false,
        showsLeftAction: Bool = false
    ) {
        titleTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )
        titleTextField.text = title
        self.showsRightAction = showsRightAction
        self.showsLeftAction = showsLeftAction

        if isLoading {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    func startAnimating() {
        setRightAccessoryVisible(false)
        titleTextField.startAnimating()
    }

    func stopAnimating() {
        titleTextField.stopAnimating()
        setRightAccessoryVisible(showsRightAction)
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
        configureActions()
        configureRightAccessory()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(titleTextField)
        titleTextField.pinTop(to: contentView.topAnchor)
        titleTextField.pinBottom(to: contentView.bottomAnchor)
        titleTextField.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        titleTextField.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }

    private func configureActions() {
        titleTextField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        rightActionButton.addTarget(self, action: #selector(handleRightActionTap), for: .touchUpInside)
        leftActionButton.addTarget(self, action: #selector(handleLeftActionTap), for: .touchUpInside)
    }

    private func configureRightAccessory() {
        rightActionButton.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        rightActionButton.contentHorizontalAlignment = .fill
        rightActionButton.contentVerticalAlignment = .fill

        leftActionButton.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        leftActionButton.contentHorizontalAlignment = .fill
        leftActionButton.contentVerticalAlignment = .fill

        rightActionContainer.addSubview(leftActionButton)
        rightActionContainer.addSubview(rightActionButton)

        titleTextField.rightView = rightSpacerView
        titleTextField.rightViewMode = .always
    }

    private func setRightAccessoryVisible(_ isVisible: Bool) {
        if isVisible {
            layoutRightAccessoryButtons()
            titleTextField.rightView = rightActionContainer
        } else {
            titleTextField.rightView = rightSpacerView
        }
        titleTextField.rightViewMode = .always
    }

    private func layoutRightAccessoryButtons() {
        let buttonSize: CGFloat = 26
        let rightInset: CGFloat = 7
        let buttonsSpacing: CGFloat = 4

        let containerWidth: CGFloat
        let rightButtonX: CGFloat

        if showsLeftAction {
            containerWidth = buttonSize * 2 + buttonsSpacing + rightInset
            rightButtonX = containerWidth - rightInset - buttonSize
            let leftButtonX = rightButtonX - buttonsSpacing - buttonSize
            leftActionButton.frame = CGRect(x: leftButtonX, y: 0, width: buttonSize, height: buttonSize)
            leftActionButton.isHidden = false
        } else {
            containerWidth = buttonSize + rightInset
            rightButtonX = containerWidth - rightInset - buttonSize
            leftActionButton.isHidden = true
        }

        rightActionButton.frame = CGRect(x: rightButtonX, y: 0, width: buttonSize, height: buttonSize)
        rightActionContainer.frame = CGRect(x: 0, y: 0, width: containerWidth, height: buttonSize)
    }

    // MARK: - Actions
    @objc
    private func handleEditingChanged() {
        onTextChanged?(titleTextField.text ?? "")
    }

    @objc
    private func handleRightActionTap() {
        onRightActionTap?()
    }

    @objc
    private func handleLeftActionTap() {
        onLeftActionTap?()
    }
}
