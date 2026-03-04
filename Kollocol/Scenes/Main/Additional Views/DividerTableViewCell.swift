//
//  DividerTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 04.03.2026.
//

import UIKit

final class DividerTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "DividerTableViewCell"

    // MARK: - UI Components
    private let dividerView: DividerView = DividerView()

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

        contentView.layer.masksToBounds = false
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    private func configureConstraints() {
        contentView.addSubview(dividerView)
        dividerView.pinCenterY(to: contentView.centerYAnchor)
        dividerView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        dividerView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
    }
}
