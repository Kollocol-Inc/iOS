//
//  TemplateQuestionsInfoTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class TemplateQuestionsInfoTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 1
        return label
    }()

    private let addQuestionButtonContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 17
        view.clipsToBounds = true
        view.setWidth(34)
        view.setHeight(34)
        return view
    }()

    private let addQuestionGlassBackgroundView: UIVisualEffectView = {
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
    }()

    private let addQuestionButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 12, weight: .semibold)
        )
        let image = UIImage(systemName: "plus", withConfiguration: symbolConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let searchToggleButtonContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 17
        view.clipsToBounds = true
        view.setWidth(34)
        view.setHeight(34)
        return view
    }()

    private let searchToggleGlassBackgroundView: UIVisualEffectView = {
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
    }()

    private let searchToggleButton: UIButton = {
        let button = UIButton(type: .system)
        return button
    }()

    private let searchToggleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .accentPrimary
        imageView.setWidth(14)
        imageView.setHeight(14)
        return imageView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionsInfoTableViewCell"

    // MARK: - Properties
    var onAddQuestionTap: (() -> Void)?
    var onSearchToggleTap: (() -> Void)?
    private var currentSearchSymbolName: String?

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
        onSearchToggleTap = nil
        currentSearchSymbolName = nil
    }

    // MARK: - Methods
    func configure(
        questionsCount: Int,
        totalScore: Int,
        totalTimeText: String,
        isSearchVisible: Bool
    ) {
        summaryLabel.attributedText = makeSummaryAttributedText(
            questionsCount: questionsCount,
            totalScore: totalScore,
            totalTimeText: totalTimeText
        )
        configureSearchToggleButton(isSearchVisible: isSearchVisible)
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
        contentView.addSubview(summaryLabel)
        summaryLabel.pinTop(to: contentView.topAnchor, 16)
        summaryLabel.pinBottom(to: contentView.bottomAnchor, 16)
        summaryLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)

        contentView.addSubview(addQuestionButtonContainerView)
        addQuestionButtonContainerView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        addQuestionButtonContainerView.pinCenterY(to: summaryLabel)

        contentView.addSubview(searchToggleButtonContainerView)
        searchToggleButtonContainerView.pinRight(to: addQuestionButtonContainerView.leadingAnchor, 8)
        searchToggleButtonContainerView.pinCenterY(to: summaryLabel)

        summaryLabel.pinRight(to: searchToggleButtonContainerView.leadingAnchor, 8, .lsOE)

        addQuestionButtonContainerView.addSubview(addQuestionGlassBackgroundView)
        addQuestionGlassBackgroundView.pin(to: addQuestionButtonContainerView)

        addQuestionButtonContainerView.addSubview(addQuestionButton)
        addQuestionButton.pin(to: addQuestionButtonContainerView)

        searchToggleButtonContainerView.addSubview(searchToggleGlassBackgroundView)
        searchToggleGlassBackgroundView.pin(to: searchToggleButtonContainerView)

        searchToggleButtonContainerView.addSubview(searchToggleButton)
        searchToggleButton.pin(to: searchToggleButtonContainerView)

        searchToggleButton.addSubview(searchToggleImageView)
        searchToggleImageView.pinCenter(to: searchToggleButton)
    }

    private func configureActions() {
        addQuestionButton.addTarget(self, action: #selector(handleAddQuestionTap), for: .touchUpInside)
        searchToggleButton.addTarget(self, action: #selector(handleSearchToggleTap), for: .touchUpInside)
    }

    private func configureSearchToggleButton(isSearchVisible: Bool) {
        let symbolName = isSearchVisible ? "xmark" : "magnifyingglass"
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 12, weight: .semibold)
        )
        guard let image = UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)?
            .withRenderingMode(.alwaysTemplate)
        else {
            return
        }

        if #available(iOS 17.0, *) {
            if currentSearchSymbolName == nil {
                searchToggleImageView.image = image
            } else if currentSearchSymbolName != symbolName {
                searchToggleImageView.setSymbolImage(
                    image,
                    contentTransition: .replace.magic(fallback: .downUp.byLayer)
                )
            }
        } else {
            searchToggleImageView.image = image
        }

        currentSearchSymbolName = symbolName
    }

    private func makeSummaryAttributedText(
        questionsCount: Int,
        totalScore: Int,
        totalTimeText: String
    ) -> NSAttributedString {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17, weight: .medium),
            .foregroundColor: UIColor.textPrimary
        ]

        let result = NSMutableAttributedString(
            string: "\(questionsCount) ",
            attributes: textAttributes
        )

        result.append(makeIconAttachment(systemName: "questionmark.bubble.fill"))
        result.append(NSAttributedString(string: "• ", attributes: textAttributes))
        result.append(
            NSAttributedString(
                string: "\(totalScore) б. • \(totalTimeText) ",
                attributes: textAttributes
            )
        )
        result.append(makeIconAttachment(systemName: "clock.fill"))
        return result
    }

    private func makeIconAttachment(systemName: String) -> NSAttributedString {
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .medium)
        )
        let image = UIImage(systemName: systemName, withConfiguration: symbolConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        let attachment = NSTextAttachment()
        attachment.image = image

        let attributedAttachment = NSMutableAttributedString(attachment: attachment)
        attributedAttachment.append(NSAttributedString(string: " "))
        return attributedAttachment
    }

    // MARK: - Actions
    @objc
    private func handleAddQuestionTap() {
        onAddQuestionTap?()
    }

    @objc
    private func handleSearchToggleTap() {
        onSearchToggleTap?()
    }
}
