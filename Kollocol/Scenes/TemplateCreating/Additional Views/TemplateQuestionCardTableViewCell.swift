//
//  TemplateQuestionCardTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit
import ShimmerView

final class TemplateQuestionCardTableViewCell: UITableViewCell {
    // MARK: - Typealias
    enum State {
        case standard
        case shimmer
    }

    private final class OptionItemView: UIView {
        // MARK: - UI Components
        private let markControl = AnswerOptionMarkControl()

        private let textLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label.textColor = .textSecondary
            label.numberOfLines = 1
            label.lineBreakMode = .byTruncatingTail
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
            kind: AnswerOptionMarkControl.Kind,
            text: String,
            isCorrect: Bool
        ) {
            textLabel.text = text
            markControl.apply(
                configuration: .init(
                    kind: kind,
                    size: .compact,
                    visualState: isCorrect ? .correct : .neutral,
                    isSelected: isCorrect
                )
            )
        }

        // MARK: - Private Methods
        private func configureUI() {
            addSubview(markControl)
            markControl.pinLeft(to: leadingAnchor)
            markControl.pinCenterY(to: centerYAnchor)

            addSubview(textLabel)
            textLabel.pinLeft(to: markControl.trailingAnchor, 8)
            textLabel.pinRight(to: trailingAnchor)
            textLabel.pinTop(to: topAnchor)
            textLabel.pinBottom(to: bottomAnchor)
        }
    }

    private final class OptionsRowView: UIView {
        // MARK: - UI Components
        private let leftOptionView = OptionItemView()
        private let rightOptionView = OptionItemView()

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
            kind: AnswerOptionMarkControl.Kind,
            leftOption: (text: String, isCorrect: Bool),
            rightOption: (text: String, isCorrect: Bool)?
        ) {
            leftOptionView.configure(
                kind: kind,
                text: leftOption.text,
                isCorrect: leftOption.isCorrect
            )

            if let rightOption {
                rightOptionView.isHidden = false
                rightOptionView.configure(
                    kind: kind,
                    text: rightOption.text,
                    isCorrect: rightOption.isCorrect
                )
            } else {
                rightOptionView.isHidden = true
            }
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

    private let shimmerCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1.5)
        view.layer.shadowRadius = 9
        view.layer.shadowOpacity = 0.1
        view.isHidden = true
        return view
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 12, weight: .medium)
        )
        let image = UIImage(systemName: "trash.fill", withConfiguration: configuration)?
            .withTintColor(.backgroundRedPrimary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        return stackView
    }()

    private let topLineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.spacing = 8
        return stackView
    }()

    private let questionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let openAnswerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .dividerPrimary
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()

    private let openAnswerLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .textSecondary
        label.numberOfLines = 4
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let optionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 18
        return stackView
    }()

    private let aiBadgeImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 8, weight: .regular)
        )
        let image = UIImage(systemName: "sparkles", withConfiguration: configuration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let aiBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 8, weight: .regular)
        label.textColor = .accentPrimary
        label.text = "ИИ"
        return label
    }()

    private let aiBadgeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 3
        stackView.isHidden = true
        return stackView
    }()

    private let metadataShimmerView = ShimmerView()
    private let deleteButtonShimmerView = ShimmerView()
    private let questionShimmerView = ShimmerView()

    private let shimmerOptionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 18
        stackView.isHidden = true
        return stackView
    }()

    private let firstOptionsRowSkeletonView = OptionsRowSkeletonView()
    private let secondOptionsRowSkeletonView = OptionsRowSkeletonView()

    // MARK: - Constants
    static let reuseIdentifier = "TemplateQuestionCardTableViewCell"

    private enum UIConstants {
        static let cardCornerRadius: CGFloat = 18
        static let cardHorizontalInset: CGFloat = 24
        static let cardVerticalInset: CGFloat = 10

        static let topInset: CGFloat = 8
        static let topHorizontalInset: CGFloat = 12
        static let questionTopInset: CGFloat = 8
        static let openAnswerTopInset: CGFloat = 12
        static let optionsTopInset: CGFloat = 12
        static let bottomInset: CGFloat = 12
        static let aiBadgeInset: CGFloat = 12
        static let aiBadgeReservedBottomInset: CGFloat = 26

        static let shimmerCardHeight: CGFloat = 148
        static let shimmerTopInset: CGFloat = 12
        static let shimmerMetadataHeight: CGFloat = 12
        static let shimmerMetadataWidthRatio: CGFloat = 0.5
        static let shimmerMetadataCornerRadius: CGFloat = 6
        static let shimmerDeleteButtonSize: CGFloat = 14
        static let shimmerDeleteButtonCornerRadius: CGFloat = 4
        static let shimmerQuestionHeight: CGFloat = 12
        static let shimmerQuestionWidthRatio: CGFloat = 0.33
        static let shimmerQuestionCornerRadius: CGFloat = 6
        static let shimmerOptionsTopInset: CGFloat = 12
        static let shimmerOptionsRowHeight: CGFloat = 14
    }

    // MARK: - Properties
    private let shimmerStyle = ShimmerViewStyle(
        baseColor: .dividerPrimary,
        highlightColor: .backgroundSecondary,
        duration: 1.2,
        interval: 0.4,
        effectSpan: .points(120),
        effectAngle: 0 * CGFloat.pi
    )

    private lazy var shimmerViews: [ShimmerView] = {
        [
            metadataShimmerView,
            deleteButtonShimmerView,
            questionShimmerView
        ] + firstOptionsRowSkeletonView.shimmerViews + secondOptionsRowSkeletonView.shimmerViews
    }()

    private var openAnswerBottomConstraint: NSLayoutConstraint?
    private var optionsBottomConstraint: NSLayoutConstraint?
    private var questionBottomConstraint: NSLayoutConstraint?
    private var cardBottomConstraint: NSLayoutConstraint?
    private var shimmerCardTopConstraint: NSLayoutConstraint?
    private var shimmerCardBottomConstraint: NSLayoutConstraint?
    private var shimmerCardHeightConstraint: NSLayoutConstraint?
    private var currentState: State = .standard

    var onDeleteTap: (() -> Void)?

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
        onDeleteTap = nil
        currentState = .standard
        questionLabel.text = nil
        metadataLabel.text = nil
        openAnswerLabel.text = nil
        openAnswerContainerView.isHidden = true
        optionsStackView.isHidden = true
        aiBadgeStackView.isHidden = true
        cardView.isHidden = false
        shimmerCardView.isHidden = true
        metadataShimmerView.isHidden = true
        deleteButtonShimmerView.isHidden = true
        questionShimmerView.isHidden = true
        shimmerOptionsStackView.isHidden = true
        stopShimmerAnimating()
        shimmerCardTopConstraint?.isActive = false
        shimmerCardBottomConstraint?.isActive = false
        shimmerCardHeightConstraint?.isActive = false
        openAnswerBottomConstraint?.isActive = false
        optionsBottomConstraint?.isActive = false
        questionBottomConstraint?.isActive = false

        optionsStackView.arrangedSubviews.forEach { view in
            optionsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    // MARK: - Methods
    func configureStandard(
        index: Int,
        question: Question,
        isAIGenerated: Bool
    ) {
        applyState(.standard)
        metadataLabel.text = makeMetadataText(index: index, question: question)
        questionLabel.text = question.text
        aiBadgeStackView.isHidden = !isAIGenerated
        updateContentBottomInset(isAIGenerated: isAIGenerated)
        cardBottomConstraint?.constant = -UIConstants.cardVerticalInset

        switch question.type {
        case .openEnded:
            configureOpenAnswer(question.correctAnswer)
        case .singleChoice:
            configureChoiceAnswers(question: question, kind: .singleChoice)
        case .multiChoice:
            configureChoiceAnswers(question: question, kind: .multipleChoice)
        case nil:
            configureChoiceAnswers(question: question, kind: .singleChoice)
        }
    }

    func configureShimmer() {
        applyState(.shimmer)
        cardBottomConstraint?.constant = -UIConstants.cardVerticalInset
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureStacks()
        configureConstraints()
        configureShimmerShape()
        configureActions()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardView.clipsToBounds = false
        cardView.layer.masksToBounds = false
        shimmerCardView.clipsToBounds = false
        shimmerCardView.layer.masksToBounds = false
    }

    private func configureStacks() {
        actionsStackView.addArrangedSubview(deleteButton)

        topLineStackView.addArrangedSubview(metadataLabel)
        topLineStackView.addArrangedSubview(actionsStackView)

        aiBadgeStackView.addArrangedSubview(aiBadgeImageView)
        aiBadgeStackView.addArrangedSubview(aiBadgeLabel)
    }

    private func configureActions() {
        deleteButton.addTarget(self, action: #selector(handleDeleteTap), for: .touchUpInside)
    }

    private func configureConstraints() {
        contentView.addSubview(cardView)
        cardView.pinTop(to: contentView.topAnchor, UIConstants.cardVerticalInset)
        cardBottomConstraint = cardView.pinBottom(to: contentView.bottomAnchor, UIConstants.cardVerticalInset)
        cardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.cardHorizontalInset)
        cardView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.cardHorizontalInset)

        cardView.addSubview(topLineStackView)
        topLineStackView.pinTop(to: cardView.topAnchor, UIConstants.topInset)
        topLineStackView.pinLeft(to: cardView.leadingAnchor, UIConstants.topHorizontalInset)
        topLineStackView.pinRight(to: cardView.trailingAnchor, UIConstants.topHorizontalInset)

        cardView.addSubview(questionLabel)
        questionLabel.pinTop(to: topLineStackView.bottomAnchor, UIConstants.questionTopInset)
        questionLabel.pinLeft(to: cardView.leadingAnchor, 12)
        questionLabel.pinRight(to: cardView.trailingAnchor, 12)

        cardView.addSubview(openAnswerContainerView)
        openAnswerContainerView.pinTop(to: questionLabel.bottomAnchor, UIConstants.openAnswerTopInset)
        openAnswerContainerView.pinLeft(to: cardView.leadingAnchor, 12)
        openAnswerContainerView.pinRight(to: cardView.trailingAnchor, 12)

        openAnswerContainerView.addSubview(openAnswerLabel)
        openAnswerLabel.pinTop(to: openAnswerContainerView.topAnchor, 12)
        openAnswerLabel.pinBottom(to: openAnswerContainerView.bottomAnchor, 12)
        openAnswerLabel.pinLeft(to: openAnswerContainerView.leadingAnchor, 12)
        openAnswerLabel.pinRight(to: openAnswerContainerView.trailingAnchor, 12)

        cardView.addSubview(optionsStackView)
        optionsStackView.pinTop(to: questionLabel.bottomAnchor, UIConstants.optionsTopInset)
        optionsStackView.pinLeft(to: cardView.leadingAnchor)
        optionsStackView.pinRight(to: cardView.trailingAnchor)

        cardView.addSubview(aiBadgeStackView)
        aiBadgeStackView.pinRight(to: cardView.trailingAnchor, UIConstants.aiBadgeInset)
        aiBadgeStackView.pinBottom(to: cardView.bottomAnchor, UIConstants.aiBadgeInset)

        openAnswerBottomConstraint = openAnswerContainerView.pinBottom(to: cardView.bottomAnchor, UIConstants.bottomInset)
        openAnswerBottomConstraint?.isActive = false

        optionsBottomConstraint = optionsStackView.pinBottom(to: cardView.bottomAnchor, UIConstants.bottomInset)
        optionsBottomConstraint?.isActive = false

        questionBottomConstraint = questionLabel.pinBottom(to: cardView.bottomAnchor, UIConstants.bottomInset)
        questionBottomConstraint?.isActive = false

        contentView.addSubview(shimmerCardView)
        shimmerCardTopConstraint = shimmerCardView.pinTop(to: contentView.topAnchor, UIConstants.cardVerticalInset)
        shimmerCardBottomConstraint = shimmerCardView.pinBottom(to: contentView.bottomAnchor, UIConstants.cardVerticalInset)
        shimmerCardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.cardHorizontalInset)
        shimmerCardView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.cardHorizontalInset)
        shimmerCardHeightConstraint = shimmerCardView.setHeight(UIConstants.shimmerCardHeight)
        shimmerCardTopConstraint?.isActive = false
        shimmerCardBottomConstraint?.isActive = false
        shimmerCardHeightConstraint?.isActive = false

        shimmerCardView.addSubview(metadataShimmerView)
        metadataShimmerView.pinTop(to: shimmerCardView.topAnchor, UIConstants.shimmerTopInset)
        metadataShimmerView.pinLeft(to: shimmerCardView.leadingAnchor, UIConstants.topHorizontalInset)
        metadataShimmerView.setHeight(UIConstants.shimmerMetadataHeight)
        metadataShimmerView.pinWidth(to: shimmerCardView.widthAnchor, UIConstants.shimmerMetadataWidthRatio)
        metadataShimmerView.isHidden = true

        shimmerCardView.addSubview(deleteButtonShimmerView)
        deleteButtonShimmerView.pinRight(to: shimmerCardView.trailingAnchor, UIConstants.topHorizontalInset)
        deleteButtonShimmerView.pinCenterY(to: metadataShimmerView.centerYAnchor)
        deleteButtonShimmerView.setWidth(UIConstants.shimmerDeleteButtonSize)
        deleteButtonShimmerView.setHeight(UIConstants.shimmerDeleteButtonSize)
        deleteButtonShimmerView.isHidden = true

        shimmerCardView.addSubview(questionShimmerView)
        questionShimmerView.pinTop(to: metadataShimmerView.bottomAnchor, UIConstants.questionTopInset)
        questionShimmerView.pinLeft(to: shimmerCardView.leadingAnchor, UIConstants.topHorizontalInset)
        questionShimmerView.setHeight(UIConstants.shimmerQuestionHeight)
        questionShimmerView.pinWidth(to: shimmerCardView.widthAnchor, UIConstants.shimmerQuestionWidthRatio)
        questionShimmerView.isHidden = true

        shimmerCardView.addSubview(shimmerOptionsStackView)
        shimmerOptionsStackView.pinTop(to: questionShimmerView.bottomAnchor, UIConstants.shimmerOptionsTopInset)
        shimmerOptionsStackView.pinLeft(to: shimmerCardView.leadingAnchor)
        shimmerOptionsStackView.pinRight(to: shimmerCardView.trailingAnchor)
        shimmerOptionsStackView.pinBottom(to: shimmerCardView.bottomAnchor, UIConstants.bottomInset)

        shimmerOptionsStackView.addArrangedSubview(firstOptionsRowSkeletonView)
        firstOptionsRowSkeletonView.setHeight(UIConstants.shimmerOptionsRowHeight)

        shimmerOptionsStackView.addArrangedSubview(secondOptionsRowSkeletonView)
        secondOptionsRowSkeletonView.setHeight(UIConstants.shimmerOptionsRowHeight)
    }

    private func updateContentBottomInset(isAIGenerated: Bool) {
        let bottomInset = isAIGenerated
            ? UIConstants.aiBadgeReservedBottomInset
            : UIConstants.bottomInset

        openAnswerBottomConstraint?.constant = -bottomInset
        optionsBottomConstraint?.constant = -bottomInset
        questionBottomConstraint?.constant = -bottomInset
    }

    private func configureShimmerShape() {
        metadataShimmerView.layer.cornerRadius = UIConstants.shimmerMetadataCornerRadius
        metadataShimmerView.layer.masksToBounds = true

        deleteButtonShimmerView.layer.cornerRadius = UIConstants.shimmerDeleteButtonCornerRadius
        deleteButtonShimmerView.layer.masksToBounds = true

        questionShimmerView.layer.cornerRadius = UIConstants.shimmerQuestionCornerRadius
        questionShimmerView.layer.masksToBounds = true
    }

    private func applyState(_ state: State) {
        guard currentState != state else {
            if state == .shimmer {
                startShimmerAnimating()
            }
            return
        }

        currentState = state
        let isShimmer = state == .shimmer

        cardView.isHidden = isShimmer
        shimmerCardView.isHidden = !isShimmer
        deleteButton.isUserInteractionEnabled = isShimmer == false
        shimmerCardTopConstraint?.isActive = isShimmer
        shimmerCardBottomConstraint?.isActive = isShimmer
        shimmerCardHeightConstraint?.isActive = isShimmer

        metadataShimmerView.isHidden = !isShimmer
        deleteButtonShimmerView.isHidden = !isShimmer
        questionShimmerView.isHidden = !isShimmer
        shimmerOptionsStackView.isHidden = !isShimmer

        if isShimmer {
            startShimmerAnimating()
        } else {
            stopShimmerAnimating()
        }
    }

    private func startShimmerAnimating() {
        shimmerViews.forEach {
            $0.apply(style: shimmerStyle)
            $0.startAnimating()
        }
    }

    private func stopShimmerAnimating() {
        shimmerViews.forEach { $0.stopAnimating() }
    }

    private func makeMetadataText(index: Int, question: Question) -> String {
        let indexText = String(format: "%02d", index + 1)
        let questionType = questionTypeText(question.type)
        let timeText: String = {
            guard let timeLimitSec = question.timeLimitSec else { return "0 с." }
            return "\(timeLimitSec)".asHmsFromSeconds() ?? "0 с."
        }()
        let scoreText = "\(question.maxScore ?? 0) б."

        return "\(indexText) • \(questionType) • \(timeText) • \(scoreText)"
    }

    private func questionTypeText(_ type: QuestionType?) -> String {
        switch type {
        case .multiChoice:
            return "MULTI"
        case .singleChoice:
            return "SINGLE"
        case .openEnded:
            return "OPEN ENDED"
        case nil:
            return "OPEN ENDED"
        }
    }

    private func configureOpenAnswer(_ correctAnswer: QuestionCorrectAnswer?) {
        let openAnswerText: String = {
            guard case let .openText(value)? = correctAnswer else { return "" }
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }()

        optionsStackView.isHidden = true
        optionsBottomConstraint?.isActive = false

        if openAnswerText.isEmpty {
            openAnswerLabel.text = nil
            openAnswerContainerView.isHidden = true
            openAnswerBottomConstraint?.isActive = false
            questionBottomConstraint?.isActive = true
        } else {
            openAnswerLabel.text = openAnswerText
            openAnswerContainerView.isHidden = false
            openAnswerBottomConstraint?.isActive = true
            questionBottomConstraint?.isActive = false
        }
    }

    private func configureChoiceAnswers(
        question: Question,
        kind: AnswerOptionMarkControl.Kind
    ) {
        openAnswerContainerView.isHidden = true
        optionsStackView.isHidden = false
        openAnswerLabel.text = nil
        questionBottomConstraint?.isActive = false

        optionsStackView.arrangedSubviews.forEach { view in
            optionsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let options = question.options ?? []
        let correctIndexes = resolveCorrectIndexes(from: question.correctAnswer)

        var currentIndex = 0
        while currentIndex < options.count {
            let leftIndex = currentIndex
            let rightIndex = currentIndex + 1

            let leftOption = (
                text: options[leftIndex],
                isCorrect: correctIndexes.contains(leftIndex)
            )

            let rightOption: (text: String, isCorrect: Bool)? = {
                guard options.indices.contains(rightIndex) else { return nil }
                return (
                    text: options[rightIndex],
                    isCorrect: correctIndexes.contains(rightIndex)
                )
            }()

            let rowView = OptionsRowView()
            rowView.configure(
                kind: kind,
                leftOption: leftOption,
                rightOption: rightOption
            )
            optionsStackView.addArrangedSubview(rowView)
            currentIndex += 2
        }

        openAnswerBottomConstraint?.isActive = false
        optionsBottomConstraint?.isActive = true
    }

    private func resolveCorrectIndexes(from correctAnswer: QuestionCorrectAnswer?) -> Set<Int> {
        switch correctAnswer {
        case .singleChoice(let index):
            return [index]
        case .multipleChoice(let indexes):
            return Set(indexes)
        case .openText, .none:
            return []
        }
    }

    @objc
    private func handleDeleteTap() {
        onDeleteTap?()
    }
}
