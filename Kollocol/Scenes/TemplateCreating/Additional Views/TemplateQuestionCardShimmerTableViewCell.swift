//
//  TemplateQuestionCardShimmerTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.04.2026.
//

import UIKit
import ShimmerView

final class TemplateQuestionCardShimmerTableViewCell: UITableViewCell, ShimmerSyncTarget {
    // MARK: - Typealias
    private final class OptionSkeletonView: UIView {
        // MARK: - UI Components
        private let markShimmerView = ShimmerView()
        private let textShimmerView = ShimmerView()

        // MARK: - Constants
        private enum UIConstants {
            static let markSize: CGFloat = 14
            static let textHeight: CGFloat = 12
            static let textLeadingInset: CGFloat = 8
            static let markCornerRadius: CGFloat = 7
            static let textCornerRadius: CGFloat = 6
        }

        // MARK: - Properties
        private let textWidth: CGFloat

        var shimmerViews: [ShimmerView] {
            [markShimmerView, textShimmerView]
        }

        // MARK: - Lifecycle
        init(textWidth: CGFloat) {
            self.textWidth = textWidth
            super.init(frame: .zero)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Methods
        private func configureUI() {
            addSubview(markShimmerView)
            markShimmerView.pinLeft(to: leadingAnchor)
            markShimmerView.pinCenterY(to: centerYAnchor)
            markShimmerView.setWidth(UIConstants.markSize)
            markShimmerView.setHeight(UIConstants.markSize)
            markShimmerView.layer.cornerRadius = UIConstants.markCornerRadius
            markShimmerView.layer.masksToBounds = true

            addSubview(textShimmerView)
            textShimmerView.pinLeft(to: markShimmerView.trailingAnchor, UIConstants.textLeadingInset)
            textShimmerView.pinRight(to: trailingAnchor, 0, .lsOE)
            textShimmerView.pinCenterY(to: centerYAnchor)
            textShimmerView.setWidth(textWidth)
            textShimmerView.setHeight(UIConstants.textHeight)
            textShimmerView.layer.cornerRadius = UIConstants.textCornerRadius
            textShimmerView.layer.masksToBounds = true
        }
    }

    private final class OptionsRowSkeletonView: UIView {
        // MARK: - UI Components
        private let leftOptionView = OptionSkeletonView(textWidth: 76)
        private let rightOptionView = OptionSkeletonView(textWidth: 76)

        // MARK: - Properties
        var shimmerViews: [ShimmerView] {
            leftOptionView.shimmerViews + rightOptionView.shimmerViews
        }

        // MARK: - Lifecycle
        override init(frame: CGRect) {
            super.init(frame: frame)
            configureUI()
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Private Methods
        private func configureUI() {
            addSubview(leftOptionView)
            leftOptionView.pinTop(to: topAnchor)
            leftOptionView.pinBottom(to: bottomAnchor)
            leftOptionView.pinLeft(to: leadingAnchor, 12)
            leftOptionView.pinRight(to: centerXAnchor, 8, .lsOE)

            addSubview(rightOptionView)
            rightOptionView.pinTop(to: topAnchor)
            rightOptionView.pinBottom(to: bottomAnchor)
            rightOptionView.pinLeft(to: centerXAnchor)
            rightOptionView.pinRight(to: trailingAnchor, 12)
        }
    }

    // MARK: - UI Components
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        view.layer.shadowRadius = 9
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let metadataShimmerView = ShimmerView()
    private let deleteButtonShimmerView = ShimmerView()
    private let questionShimmerView = ShimmerView()

    private let optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 18
        return stackView
    }()

    private let firstOptionsRowView = OptionsRowSkeletonView()
    private let secondOptionsRowView = OptionsRowSkeletonView()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionCardShimmerTableViewCell"

    private enum UIConstants {
        static let cardHorizontalInset: CGFloat = 24
        static let cardVerticalInset: CGFloat = 10
        static let cardHeight: CGFloat = 148

        static let topInset: CGFloat = 12
        static let topHorizontalInset: CGFloat = 12
        static let metadataHeight: CGFloat = 12
        static let metadataWidthRatio: CGFloat = 0.5
        static let metadataCornerRadius: CGFloat = 6

        static let deleteButtonSize: CGFloat = 14
        static let deleteButtonCornerRadius: CGFloat = 4

        static let questionTopInset: CGFloat = 8
        static let questionHeight: CGFloat = 12
        static let questionWidthRatio: CGFloat = 0.33
        static let questionCornerRadius: CGFloat = 6

        static let optionsTopInset: CGFloat = 12
        static let optionsRowHeight: CGFloat = 14
        static let bottomInset: CGFloat = 12
    }

    // MARK: - Properties
    let style = ShimmerViewStyle(
        baseColor: .dividerPrimary,
        highlightColor: .backgroundSecondary,
        duration: 1.2,
        interval: 0.4,
        effectSpan: .points(120),
        effectAngle: 0 * CGFloat.pi
    )

    var effectBeginTime: CFTimeInterval = 0

    private lazy var shimmerViews: [ShimmerView] = {
        [
            metadataShimmerView,
            deleteButtonShimmerView,
            questionShimmerView
        ] + firstOptionsRowView.shimmerViews + secondOptionsRowView.shimmerViews
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

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
        startAnimating()
    }

    // MARK: - Methods
    func startAnimating() {
        effectBeginTime = CACurrentMediaTime()
        shimmerViews.forEach {
            $0.apply(style: style)
            $0.startAnimating()
        }
    }

    func stopAnimating() {
        shimmerViews.forEach { $0.stopAnimating() }
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureConstraints()
        configureSkeletonShape()
        startAnimating()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardView.clipsToBounds = false
        cardView.layer.masksToBounds = false
    }

    private func configureConstraints() {
        contentView.addSubview(cardView)
        cardView.pinTop(to: contentView.topAnchor, UIConstants.cardVerticalInset)
        cardView.pinBottom(to: contentView.bottomAnchor, UIConstants.cardVerticalInset)
        cardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.cardHorizontalInset)
        cardView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.cardHorizontalInset)
        cardView.setHeight(UIConstants.cardHeight)

        cardView.addSubview(metadataShimmerView)
        metadataShimmerView.pinTop(to: cardView.topAnchor, UIConstants.topInset)
        metadataShimmerView.pinLeft(to: cardView.leadingAnchor, UIConstants.topHorizontalInset)
        metadataShimmerView.setHeight(UIConstants.metadataHeight)
        metadataShimmerView.pinWidth(to: cardView.widthAnchor, UIConstants.metadataWidthRatio)

        cardView.addSubview(deleteButtonShimmerView)
        deleteButtonShimmerView.pinRight(to: cardView.trailingAnchor, UIConstants.topHorizontalInset)
        deleteButtonShimmerView.pinCenterY(to: metadataShimmerView.centerYAnchor)
        deleteButtonShimmerView.setWidth(UIConstants.deleteButtonSize)
        deleteButtonShimmerView.setHeight(UIConstants.deleteButtonSize)

        cardView.addSubview(questionShimmerView)
        questionShimmerView.pinTop(to: metadataShimmerView.bottomAnchor, UIConstants.questionTopInset)
        questionShimmerView.pinLeft(to: cardView.leadingAnchor, UIConstants.topHorizontalInset)
        questionShimmerView.setHeight(UIConstants.questionHeight)
        questionShimmerView.pinWidth(to: cardView.widthAnchor, UIConstants.questionWidthRatio)

        cardView.addSubview(optionsStackView)
        optionsStackView.pinTop(to: questionShimmerView.bottomAnchor, UIConstants.optionsTopInset)
        optionsStackView.pinLeft(to: cardView.leadingAnchor)
        optionsStackView.pinRight(to: cardView.trailingAnchor)
        optionsStackView.pinBottom(to: cardView.bottomAnchor, UIConstants.bottomInset)

        optionsStackView.addArrangedSubview(firstOptionsRowView)
        firstOptionsRowView.setHeight(UIConstants.optionsRowHeight)

        optionsStackView.addArrangedSubview(secondOptionsRowView)
        secondOptionsRowView.setHeight(UIConstants.optionsRowHeight)
    }

    private func configureSkeletonShape() {
        metadataShimmerView.layer.cornerRadius = UIConstants.metadataCornerRadius
        metadataShimmerView.layer.masksToBounds = true

        deleteButtonShimmerView.layer.cornerRadius = UIConstants.deleteButtonCornerRadius
        deleteButtonShimmerView.layer.masksToBounds = true

        questionShimmerView.layer.cornerRadius = UIConstants.questionCornerRadius
        questionShimmerView.layer.masksToBounds = true
    }
}
