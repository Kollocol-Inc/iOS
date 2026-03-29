//
//  QuizParticipatingInfoPillView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingInfoPillView: UIView {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .textWhite
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(
        iconName: String,
        text: String,
        tintColor: UIColor
    ) {
        titleLabel.attributedText = makeAttributedText(
            iconName: iconName,
            text: text,
            tintColor: tintColor
        )
        titleLabel.alpha = 1
    }

    func configureEmpty() {
        titleLabel.attributedText = nil
        titleLabel.alpha = 0
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .accentPrimary
        layer.cornerRadius = 18
        clipsToBounds = true

        addSubview(titleLabel)
        titleLabel.pinLeft(to: leadingAnchor, 10)
        titleLabel.pinRight(to: trailingAnchor, 10)
        titleLabel.pinCenterY(to: centerYAnchor)
    }

    private func makeAttributedText(
        iconName: String,
        text: String,
        tintColor: UIColor
    ) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: tintColor
        ]

        let result = NSMutableAttributedString()

        let attachment = NSTextAttachment()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        attachment.image = UIImage(systemName: iconName, withConfiguration: imageConfiguration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)

        result.append(NSAttributedString(attachment: attachment))
        result.append(NSAttributedString(string: " \(text)", attributes: textAttributes))
        return result
    }
}
