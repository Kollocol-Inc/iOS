//
//  TemplateNameInputTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import UIKit

final class TemplateNameInputTableViewCell: UITableViewCell {
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
        field.addPadding(side: 12)
        field.setHeight(38)
        return field
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateNameInputTableViewCell"

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?

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

    // MARK: - Methods
    func configure(title: String?, isLoading: Bool) {
        titleTextField.text = title

        if isLoading {
            startAnimating()
        } else {
            stopAnimating()
        }
    }

    func startAnimating() {
        titleTextField.startAnimating()
    }

    func stopAnimating() {
        titleTextField.stopAnimating()
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
        contentView.addSubview(titleTextField)
        titleTextField.pinTop(to: contentView.topAnchor)
        titleTextField.pinBottom(to: contentView.bottomAnchor)
        titleTextField.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        titleTextField.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }

    private func configureActions() {
        titleTextField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
    }

    // MARK: - Actions
    @objc
    private func handleEditingChanged() {
        onTextChanged?(titleTextField.text ?? "")
    }
}
