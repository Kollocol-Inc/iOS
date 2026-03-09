//
//  QuizCardView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 09.03.2026.
//

import UIKit

final class QuizCardView: UIView {
    // MARK: - UI Components
    private let rightChevronImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20, weight: .medium))
        let image = UIImage(systemName: "chevron.right", withConfiguration: configuration)?
            .withTintColor(
                .accentPrimary,
                renderingMode: .alwaysOriginal
            )
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let startQuizButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setImage(
            UIImage(systemName: "play.fill")?.withTintColor(.textWhite, renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.setWidth(44)
        button.setHeight(44)
        return button
    }()

    private let quizNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let quizTypeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .textSecondary
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let quizTypeImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 12, weight: .regular))
        let image = UIImage(systemName: "info.circle", withConfiguration: configuration)?
            .withTintColor(
                .textSecondary,
                renderingMode: .alwaysOriginal
            )
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let quizTypeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()

    private let quizInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .trailing
        return stackView
    }()

    private let totalTimeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()

    private let totalTimeImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .regular))
        let image = UIImage(systemName: "clock.fill", withConfiguration: configuration)?
            .withTintColor(
                .accentPrimary,
                renderingMode: .alwaysOriginal
            )
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let totalTimeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()

    private let totalQuestionsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()

    private let totalQuestionsImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .regular))
        let image = UIImage(systemName: "questionmark.bubble.fill", withConfiguration: configuration)?
            .withTintColor(
                .accentPrimary,
                renderingMode: .alwaysOriginal
            )
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let totalQuestionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()

    private let deadlineLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .right
        return label
    }()

    private let deadlineImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 14, weight: .regular))
        let image = UIImage(systemName: "calendar.badge.clock", withConfiguration: configuration)?
            .withTintColor(
                .accentPrimary,
                renderingMode: .alwaysOriginal
            )
        let imageView = UIImageView(image: image)
        return imageView
    }()

    private let deadlineStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        return stackView
    }()

    private let dividerView = DividerView()

    // MARK: - Constants
    private enum UIConstants {
        static let cornerRadius: CGFloat = 18
        static let cardShadowRadius: CGFloat = 20
        static let cardShadowOpacity: Float = 0.2

        static let contentInset: CGFloat = 16
        static let startButtonInset: CGFloat = 10
        static let topInset: CGFloat = 12
        static let bottomInset: CGFloat = 16
        static let dividerBottomSpacing: CGFloat = 12
        static let quizTypeBottomSpacing: CGFloat = 6
    }

    // MARK: - Properties
    var onQuizTypeTap: ((QuizType) -> Void)?
    var onQuizStartTap: (() -> Void)?

    private var currentQuizType: QuizType?

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
    func configure(with item: QuizInstanceViewData, isTemplate: Bool) {
        currentQuizType = item.quizType
        quizNameLabel.text = item.title

        codeLabel.text = item.accessCode
        codeLabel.isHidden = isTemplate || item.accessCode == nil

        if let quizType = item.quizType {
            quizTypeLabel.text = quizType.displayName
            quizTypeStackView.isHidden = false
        } else {
            quizTypeLabel.text = nil
            quizTypeStackView.isHidden = true
        }

        totalTimeLabel.text = item.totalTime
        totalTimeStackView.isHidden = item.totalTime == nil

        totalQuestionsLabel.text = item.totalQuestions
        totalQuestionsStackView.isHidden = item.totalQuestions == nil

        deadlineLabel.text = item.deadline
        deadlineStackView.isHidden = item.deadline == nil

        startQuizButton.isHidden = !isTemplate
        startQuizButton.isEnabled = isTemplate
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .backgroundSecondary
        layer.cornerRadius = UIConstants.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = UIConstants.cardShadowRadius
        layer.shadowOpacity = UIConstants.cardShadowOpacity
        clipsToBounds = false

        configureQuizTypeStackView()
        configureQuizInfoStackView()
        configureConstraints()
        configureActions()
    }

    private func configureQuizTypeStackView() {
        quizTypeStackView.addArrangedSubview(quizTypeLabel)
        quizTypeStackView.addArrangedSubview(quizTypeImageView)
    }

    private func configureQuizInfoStackView() {
        totalTimeStackView.addArrangedSubview(totalTimeLabel)
        totalTimeStackView.addArrangedSubview(totalTimeImageView)

        totalQuestionsStackView.addArrangedSubview(totalQuestionsLabel)
        totalQuestionsStackView.addArrangedSubview(totalQuestionsImageView)

        deadlineStackView.addArrangedSubview(deadlineLabel)
        deadlineStackView.addArrangedSubview(deadlineImageView)

        quizInfoStackView.addArrangedSubview(totalTimeStackView)
        quizInfoStackView.addArrangedSubview(totalQuestionsStackView)
        quizInfoStackView.addArrangedSubview(deadlineStackView)
    }

    private func configureConstraints() {
        addSubview(rightChevronImageView)
        rightChevronImageView.pinRight(to: trailingAnchor, UIConstants.contentInset)
        rightChevronImageView.pinBottom(to: bottomAnchor, UIConstants.bottomInset)

        addSubview(quizNameLabel)
        quizNameLabel.pinLeft(to: leadingAnchor, UIConstants.contentInset)
        quizNameLabel.pinBottom(to: bottomAnchor, UIConstants.bottomInset)
        quizNameLabel.pinRight(to: rightChevronImageView.leadingAnchor, 8, .lsOE)

        addSubview(dividerView)
        dividerView.pinBottom(to: quizNameLabel.topAnchor, UIConstants.dividerBottomSpacing)
        dividerView.pinLeft(to: leadingAnchor, UIConstants.contentInset)
        dividerView.pinRight(to: trailingAnchor, UIConstants.contentInset)

        addSubview(codeLabel)
        codeLabel.pinTop(to: topAnchor, UIConstants.topInset)
        codeLabel.pinLeft(to: leadingAnchor, UIConstants.contentInset)

        addSubview(startQuizButton)
        startQuizButton.pinTop(to: topAnchor, UIConstants.startButtonInset)
        startQuizButton.pinLeft(to: leadingAnchor, UIConstants.startButtonInset)

        addSubview(quizTypeStackView)
        quizTypeStackView.pinLeft(to: leadingAnchor, UIConstants.contentInset)
        quizTypeStackView.pinBottom(to: dividerView.topAnchor, UIConstants.quizTypeBottomSpacing)
        quizTypeStackView.pinRight(to: trailingAnchor, UIConstants.contentInset, .lsOE)

        addSubview(quizInfoStackView)
        quizInfoStackView.pinTop(to: topAnchor, UIConstants.topInset)
        quizInfoStackView.pinRight(to: trailingAnchor, UIConstants.contentInset)

        codeLabel.pinRight(to: quizInfoStackView.leadingAnchor, 8, .lsOE)
    }

    private func configureActions() {
        quizTypeStackView.isUserInteractionEnabled = true
        let quizTypeTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleQuizTypeTap))
        quizTypeStackView.addGestureRecognizer(quizTypeTapGesture)

        startQuizButton.addTarget(self, action: #selector(handleStartQuizTap), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc
    private func handleQuizTypeTap() {
        guard let quizType = currentQuizType else { return }
        onQuizTypeTap?(quizType)
    }

    @objc
    private func handleStartQuizTap() {
        onQuizStartTap?()
    }
}
