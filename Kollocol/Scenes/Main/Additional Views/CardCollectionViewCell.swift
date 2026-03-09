//
//  CardCollectionViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 01.03.2026.
//

import UIKit

final class CardCollectionViewCell: UICollectionViewCell {

    // MARK: - Constants

    static let reuseIdentifier = "CardCollectionViewCell"

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 18
        view.layer.masksToBounds = false
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private let codeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let quizNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

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
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    private let quizInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .trailing
        return stack
    }()

    private let dividerView = DividerView()

    private let startQuizButton: UIButton = {
        let button = UIButton()
        button.setWidth(44)
        button.setHeight(44)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setImage(UIImage(systemName: "play.fill")?.withTintColor(.textWhite, renderingMode: .alwaysOriginal), for: .normal)
        return button
    }()

    // total time

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
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    // total questions

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
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    // deadline

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
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        onQuizTypeTap = nil
        currentQuizType = nil
        quizTypeStackView.isHidden = false
    }

    // MARK: - Methods

    func configure(with item: QuizInstanceViewData?, isTemplate: Bool = false) {
        quizNameLabel.text = item?.title
        currentQuizType = item?.quizType

        if (isTemplate == false) { startQuizButton.removeFromSuperview() }

        if let quizCode = item?.accessCode {
            codeLabel.text = quizCode
        } else {
            codeLabel.removeFromSuperview()
        }

        if let quizType = item?.quizType {
            quizTypeLabel.text = quizType.displayName
        } else {
            quizTypeLabel.removeFromSuperview()
        }

        if let totalTime = item?.totalTime {
            totalTimeLabel.text = totalTime
        } else {
            quizInfoStackView.removeArrangedSubview(totalTimeStackView)
        }

        if let totalQuestions = item?.totalQuestions {
            totalQuestionsLabel.text = totalQuestions
        } else {
            quizInfoStackView.removeArrangedSubview(totalQuestionsStackView)
        }

        if let deadline = item?.deadline {
            deadlineLabel.text = deadline
        } else {
            quizInfoStackView.removeArrangedSubview(deadlineStackView)
        }
    }

    // MARK: - Private Methods

    private func configureUI() {
        configureBackground()
        configureConstraints()
    }

    private func  configureBackground() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        clipsToBounds = false
        layer.masksToBounds = false
        contentView.clipsToBounds = false
        contentView.layer.masksToBounds = false
    }

    private func configureConstraints() {
        contentView.addSubview(cardView)

        cardView.pinVertical(to: contentView)
        cardView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        cardView.pinCenterX(to: contentView.centerXAnchor)

        cardView.addSubview(rightChevronImageView)
        rightChevronImageView.pinRight(to: cardView.trailingAnchor, 16)
        rightChevronImageView.pinBottom(to: cardView.bottomAnchor, 16)

        cardView.addSubview(quizNameLabel)
        quizNameLabel.pinLeft(to: cardView.leadingAnchor, 16)
        quizNameLabel.pinBottom(to: cardView.bottomAnchor, 16)

        cardView.addSubview(dividerView)
        dividerView.pinBottom(to: quizNameLabel.topAnchor, 12)
        dividerView.pinLeft(to: cardView.leadingAnchor, 16)
        dividerView.pinCenterX(to: cardView.centerXAnchor)

        cardView.addSubview(codeLabel)
        codeLabel.pinTop(to: cardView.topAnchor, 12)
        codeLabel.pinLeft(to: cardView.leadingAnchor, 16)

        cardView.addSubview(startQuizButton)
        startQuizButton.pinTop(to: cardView.topAnchor, 10)
        startQuizButton.pinLeft(to: cardView.leadingAnchor, 10)
        startQuizButton.addTarget(self, action: #selector(handleStartQuizTap), for: .touchUpInside)

        cardView.addSubview(quizTypeStackView)
        quizTypeStackView.pinLeft(to: cardView.leadingAnchor, 16)
        quizTypeStackView.pinBottom(to: dividerView.topAnchor, 6)
        quizTypeStackView.addArrangedSubview(quizTypeLabel)
        quizTypeStackView.addArrangedSubview(quizTypeImageView)
        quizTypeStackView.isUserInteractionEnabled = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleQuizTypeTap))
        quizTypeStackView.addGestureRecognizer(tapGesture)

        totalTimeStackView.addArrangedSubview(totalTimeLabel)
        totalTimeStackView.addArrangedSubview(totalTimeImageView)

        totalQuestionsStackView.addArrangedSubview(totalQuestionsLabel)
        totalQuestionsStackView.addArrangedSubview(totalQuestionsImageView)

        deadlineStackView.addArrangedSubview(deadlineLabel)
        deadlineStackView.addArrangedSubview(deadlineImageView)

        cardView.addSubview(quizInfoStackView)
        quizInfoStackView.pinRight(to: cardView.trailingAnchor, 16)
        quizInfoStackView.pinTop(to: cardView.topAnchor, 12)
        quizInfoStackView.addArrangedSubview(totalTimeStackView)
        quizInfoStackView.addArrangedSubview(totalQuestionsStackView)
        quizInfoStackView.addArrangedSubview(deadlineStackView)
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
