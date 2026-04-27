//
//  TemplateQuestionsSearchTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class TemplateQuestionsSearchTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let field = UITextField()
        field.attributedPlaceholder = NSAttributedString(
            string: "searchQuestions".localized,
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .done

        let iconConfiguration = UIImage.SymbolConfiguration(
            font: UIFont.systemFont(ofSize: 15, weight: .medium)
        )
        let iconImage = UIImage(systemName: "magnifyingglass", withConfiguration: iconConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.frame = CGRect(x: 12, y: 14.5, width: 15, height: 15)

        let leftAccessoryView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 44))
        leftAccessoryView.addSubview(iconImageView)
        field.leftView = leftAccessoryView
        field.leftViewMode = .always

        field.addPadding(right: 12)
        field.setHeight(44)
        return field
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionsSearchTableViewCell"

    // MARK: - Properties
    var onEditingDidEnd: ((String) -> Void)?

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
        onEditingDidEnd = nil
    }

    // MARK: - Methods
    func configure(
        text: String,
        shouldFocus: Bool
    ) {
        searchTextField.text = text
        if shouldFocus {
            DispatchQueue.main.async { [weak self] in
                self?.searchTextField.becomeFirstResponder()
            }
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(searchTextField)
        searchTextField.pinTop(to: contentView.topAnchor, 8)
        searchTextField.pinBottom(to: contentView.bottomAnchor, 8)
        searchTextField.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        searchTextField.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        searchTextField.addTarget(self, action: #selector(handleEditingDidEnd), for: .editingDidEnd)
        searchTextField.addTarget(self, action: #selector(handleEditingDidEndOnExit), for: .editingDidEndOnExit)
    }

    // MARK: - Actions
    @objc
    private func handleEditingDidEnd() {
        onEditingDidEnd?(searchTextField.text ?? "")
    }

    @objc
    private func handleEditingDidEndOnExit() {
        searchTextField.resignFirstResponder()
    }
}
