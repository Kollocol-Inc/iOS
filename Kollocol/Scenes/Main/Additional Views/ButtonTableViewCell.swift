//
//  ButtonTableViewCell.swift
//  Kollocol
//
//  Created by Arseniy on 28.02.2026.
//

import UIKit

final class ButtonTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "ButtonTableViewCell"
    
    // MARK: - UI Components
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.tintColor = .textWhite
        return button
    }()
    
    private let loader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .textWhite
        view.hidesWhenStopped = true
        return view
    }()
    
    // MARK: - Properties
    private var action: (() -> Void)?
    private var title: String?
    
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
    func configure(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        
        let attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.setAttributedTitle(attributedTitle, for: .disabled)
    }
    
    func setLoading(_ isLoading: Bool) {
        if isLoading {
            button.setAttributedTitle(nil, for: .normal)
            button.setAttributedTitle(nil, for: .disabled)
            loader.startAnimating()
            button.isEnabled = false
        } else {
            if let title = title {
                let attributedTitle = NSAttributedString(
                    string: title,
                    attributes: [
                        .foregroundColor: UIColor.textWhite,
                        .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                    ]
                )
                button.setAttributedTitle(attributedTitle, for: .normal)
                button.setAttributedTitle(attributedTitle, for: .disabled)
            }
            loader.stopAnimating()
        }
    }
    
    func setEnabled(_ isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1.0 : 0.6
    }
    
    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(button)
        button.pinLeft(to: contentView.leadingAnchor, 32)
        button.pinRight(to: contentView.trailingAnchor, 32)
        button.pinTop(to: contentView.topAnchor, 8)
        button.pinBottom(to: contentView.bottomAnchor, 16)
        button.setHeight(42)
        
        button.addSubview(loader)
        loader.pinCenter(to: button)
        
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc
    private func buttonTapped() {
        action?()
    }
}
