//
//  CardTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.02.2026.
//

import UIKit

final class CardTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "CardTableViewCell"

    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        return view
    }()

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .backgroundSecondary
        clipsToBounds = false
        layer.masksToBounds = false
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
    }

    private func configureConstraints() {
        contentView.addSubview(cardView)
        cardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        cardView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        cardView.pinVertical(to: contentView)
        cardView.setHeight(150)
    }
}
