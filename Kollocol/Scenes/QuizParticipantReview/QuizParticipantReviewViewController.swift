//
//  QuizParticipantReviewViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantReviewViewController: UIViewController {
    // MARK: - UI Components
    private let tableBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 28
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.sectionHeaderTopPadding = 0
        table.keyboardDismissMode = .onDrag
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    private let bottomIslandView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 28
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        return view
    }()

    private let bottomButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 12
        return stackView
    }()

    private let scoreControlView: QuizParticipantReviewScoreControlView = {
        let view = QuizParticipantReviewScoreControlView()
        view.setHeight(42)
        return view
    }()

    private let scoreControlsContainerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private let aiReviewButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 14, weight: .semibold)
        )
        let image = UIImage(systemName: "wand.and.sparkles.inverse", withConfiguration: configuration)?
            .withTintColor(.buttonSecondary, renderingMode: .alwaysOriginal)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.buttonSecondary.cgColor
        button.setTitleColor(.buttonSecondary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setImage(image, for: .normal)
        button.setTitle("ИИ", for: .normal)
        button.semanticContentAttribute = .forceLeftToRight
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        button.setHeight(42)
        return button
    }()

    private let gradeButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Оценить", for: .normal)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    private let navigationButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private let previousQuestionButton: UIButton = {
        let button = UIButton(type: .system)
        let chevronConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 10, weight: .semibold)
        )
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Назад", for: .normal)
        button.setImage(
            UIImage(systemName: "chevron.left", withConfiguration: chevronConfiguration)?
                .withTintColor(.textWhite, renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.semanticContentAttribute = .forceLeftToRight
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    private let nextQuestionButton: UIButton = {
        let button = UIButton(type: .system)
        let chevronConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 10, weight: .semibold)
        )
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Вперед", for: .normal)
        button.setImage(
            UIImage(systemName: "chevron.right", withConfiguration: chevronConfiguration)?
                .withTintColor(.textWhite, renderingMode: .alwaysOriginal),
            for: .normal
        )
        button.semanticContentAttribute = .forceRightToLeft
        button.imageView?.contentMode = .scaleAspectFit
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .textPrimary
        label.textAlignment = .center
        return label
    }()

    private let navigationSubtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private lazy var navigationTitleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [navigationTitleLabel, navigationSubtitleLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 0
        return stackView
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let defaultQuizTitle = "Квиз"
        static let defaultParticipantName = "Участник"
        static let questionSwitcherRowHeight: CGFloat = 76

        static let completionPendingTitle = "Внимание"
        static let completionPendingDescription = "Осталось %@ вопросов, ожидающих оценки"

        static let completionDoneTitle = "Квиз полностью проверен"
        static let completionDoneDescription = "Все вопросы оценены"

        static let aiReviewConfirmationTitle = "Подтверждение"
        static let aiReviewConfirmationDescription = "Вы уверены, что хотите получить рекомендацию от ИИ?"
    }

    // MARK: - Properties
    private let interactor: QuizParticipantReviewInteractor
    private let initialData: QuizParticipantReviewModels.InitialData

    private var rows: [QuizParticipantReviewModels.Row] = [
        .header(title: UIConstants.defaultQuizTitle),
        .empty(text: "Загрузка...")
    ]
    private var selectedQuestionIndex = 0
    private var checkmarkState: QuizParticipantReviewModels.CheckmarkState = .pending(pendingOpenQuestionsCount: 0)
    private var scoreControlState: QuizParticipantReviewModels.ScoreControlViewData = .init(
        score: 0,
        maxScore: 0,
        isMinusEnabled: false,
        isPlusEnabled: false,
        isVisible: false
    )
    private var bottomControlsState: QuizParticipantReviewModels.BottomControlsViewData = .init(
        isVisible: false,
        showsGradeButton: false,
        showsAIReviewButton: false,
        canGoPrevious: false,
        canGoNext: false
    )

    private var scoreButtonsBottomConstraint: NSLayoutConstraint?
    private var bottomIslandBottomConstraint: NSLayoutConstraint?
    private var previousNavigationBarTintColor: UIColor?
    private var previousBackIndicatorImage: UIImage?
    private var previousBackIndicatorTransitionMaskImage: UIImage?
    private var keyboardBottomOffset: CGFloat = 0

    private var shouldShowBottomIsland: Bool {
        bottomControlsState.isVisible
    }

    // MARK: - Lifecycle
    init(
        interactor: QuizParticipantReviewInteractor,
        initialData: QuizParticipantReviewModels.InitialData
    ) {
        self.interactor = interactor
        self.initialData = initialData
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        configureUI()
        configureNavigationBar()
        configureKeyboardObservers()
        updateBottomIslandVisibility()

        Task {
            await interactor.handleViewDidLoad()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBackButtonAppearance()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreBackButtonAppearance()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableInsetsForBottomIsland()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateBottomIslandButtonsInset()
        updateTableInsetsForBottomIsland()
    }

    // MARK: - Methods
    @MainActor
    func displayViewData(_ viewData: QuizParticipantReviewModels.ViewData) {
        rows = viewData.rows
        selectedQuestionIndex = viewData.selectedQuestionIndex
        checkmarkState = viewData.checkmarkState
        scoreControlState = viewData.scoreControl
        bottomControlsState = viewData.bottomControls

        scoreControlView.configure(
            score: scoreControlState.score,
            isMinusEnabled: scoreControlState.isMinusEnabled,
            isPlusEnabled: scoreControlState.isPlusEnabled
        )

        updateCompletionButton()
        updateBottomIslandVisibility()
        tableView.reloadData()
        updateTableInsetsForBottomIsland()
    }

    @MainActor
    func displayCompletionInfo(pendingOpenQuestionsCount: Int) {
        if pendingOpenQuestionsCount > 0 {
            let description = UIConstants.completionPendingDescription.replacingOccurrences(
                of: "%@",
                with: "\(pendingOpenQuestionsCount)"
            )
            showInfoBottomSheet(
                title: UIConstants.completionPendingTitle,
                description: description,
                buttonTitle: "ОК"
            )
            return
        }

        showInfoBottomSheet(
            title: UIConstants.completionDoneTitle,
            description: UIConstants.completionDoneDescription,
            buttonTitle: "ОК"
        )
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
        configureActions()
    }

    private func configureConstraints() {
        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinLeft(to: view.leadingAnchor)
        tableBackgroundView.pinRight(to: view.trailingAnchor)
        tableBackgroundView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 8)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)

        view.addSubview(bottomIslandView)
        bottomIslandView.pinLeft(to: view.leadingAnchor)
        bottomIslandView.pinRight(to: view.trailingAnchor)
        bottomIslandBottomConstraint = bottomIslandView.pinBottom(to: view.bottomAnchor)

        bottomIslandView.addSubview(bottomButtonsStackView)
        bottomButtonsStackView.pinTop(to: bottomIslandView.topAnchor, 12)
        bottomButtonsStackView.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        bottomButtonsStackView.pinRight(to: bottomIslandView.trailingAnchor, 12)
        scoreButtonsBottomConstraint = bottomButtonsStackView.pinBottom(to: bottomIslandView.bottomAnchor)

        bottomButtonsStackView.addArrangedSubview(scoreControlsContainerStackView)
        scoreControlsContainerStackView.addArrangedSubview(scoreControlView)
        scoreControlsContainerStackView.addArrangedSubview(aiReviewButton)
        bottomButtonsStackView.addArrangedSubview(gradeButton)
        bottomButtonsStackView.addArrangedSubview(navigationButtonsStackView)
        navigationButtonsStackView.addArrangedSubview(previousQuestionButton)
        navigationButtonsStackView.addArrangedSubview(nextQuestionButton)

        updateBottomIslandButtonsInset()
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(
            QuizParticipantReviewQuestionSwitcherTableViewCell.self,
            forCellReuseIdentifier: QuizParticipantReviewQuestionSwitcherTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingQuestionTextTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingQuestionTextTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingOpenAnswerTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingOpenAnswerTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipantReviewOptionTableViewCell.self,
            forCellReuseIdentifier: QuizParticipantReviewOptionTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipantReviewAnswerInfoTableViewCell.self,
            forCellReuseIdentifier: QuizParticipantReviewAnswerInfoTableViewCell.reuseIdentifier
        )
        tableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureActions() {
        aiReviewButton.addTarget(self, action: #selector(handleAIReviewTap), for: .touchUpInside)
        gradeButton.addTarget(self, action: #selector(handleGradeTap), for: .touchUpInside)
        previousQuestionButton.addTarget(self, action: #selector(handlePreviousQuestionTap), for: .touchUpInside)
        nextQuestionButton.addTarget(self, action: #selector(handleNextQuestionTap), for: .touchUpInside)
        scoreControlView.onMinusTap = { [weak self] in
            Task { [weak self] in
                await self?.interactor.handleDecreaseScoreTap()
            }
        }
        scoreControlView.onPlusTap = { [weak self] in
            Task { [weak self] in
                await self?.interactor.handleIncreaseScoreTap()
            }
        }
        scoreControlView.onScoreInputCommit = { [weak self] text in
            Task { [weak self] in
                await self?.interactor.handleScoreInputCommit(text)
            }
        }
    }

    private func configureNavigationBar() {
        let normalizedName = initialData.participantFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmail = initialData.participantEmail?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        navigationTitleLabel.text = normalizedName.isEmpty ? UIConstants.defaultParticipantName : normalizedName
        navigationSubtitleLabel.text = normalizedEmail
        navigationSubtitleLabel.isHidden = normalizedEmail.isEmpty
        navigationItem.titleView = navigationTitleStackView

        updateCompletionButton()
    }

    private func updateCompletionButton() {
        let tintColor: UIColor = {
            switch checkmarkState {
            case .pending:
                return .textSecondary
            case .complete:
                return .backgroundGreen
            }
        }()

        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let image = UIImage(systemName: "checkmark", withConfiguration: configuration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)

        let action = UIAction { [weak self] _ in
            Task { [weak self] in
                await self?.interactor.handleCompletionTap()
            }
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, primaryAction: action)
    }

    private func updateBottomIslandVisibility() {
        let isVisible = shouldShowBottomIsland
        bottomIslandView.isHidden = isVisible == false

        scoreControlView.isHidden = scoreControlState.isVisible == false
        aiReviewButton.isHidden = bottomControlsState.showsAIReviewButton == false
        scoreControlsContainerStackView.isHidden = scoreControlView.isHidden && aiReviewButton.isHidden

        gradeButton.isHidden = bottomControlsState.showsGradeButton == false
        navigationButtonsStackView.isHidden = bottomControlsState.showsGradeButton

        aiReviewButton.isEnabled = isVisible && bottomControlsState.showsAIReviewButton
        aiReviewButton.alpha = aiReviewButton.isEnabled ? 1 : 0.6

        gradeButton.isEnabled = isVisible && bottomControlsState.showsGradeButton
        gradeButton.alpha = gradeButton.isEnabled ? 1 : 0.6

        previousQuestionButton.isEnabled = bottomControlsState.canGoPrevious
        previousQuestionButton.alpha = bottomControlsState.canGoPrevious ? 1 : 0.6

        nextQuestionButton.isEnabled = bottomControlsState.canGoNext
        nextQuestionButton.alpha = bottomControlsState.canGoNext ? 1 : 0.6

        view.layoutIfNeeded()
    }

    private func updateBottomIslandButtonsInset() {
        scoreButtonsBottomConstraint?.constant = -view.safeAreaInsets.bottom
    }

    private func updateTableInsetsForBottomIsland() {
        guard shouldShowBottomIsland else {
            tableView.contentInset.bottom = 0
            tableView.verticalScrollIndicatorInsets.bottom = 0
            return
        }

        let bottomInset = bottomIslandView.bounds.height + 8 + keyboardBottomOffset
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func applyBackButtonAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        if previousNavigationBarTintColor == nil {
            previousNavigationBarTintColor = navigationBar.tintColor
        }
        if previousBackIndicatorImage == nil {
            previousBackIndicatorImage = navigationBar.backIndicatorImage
        }
        if previousBackIndicatorTransitionMaskImage == nil {
            previousBackIndicatorTransitionMaskImage = navigationBar.backIndicatorTransitionMaskImage
        }

        navigationBar.tintColor = .textSecondary

        let backConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let backImage = UIImage(systemName: "chevron.backward", withConfiguration: backConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)

        if let backImage {
            navigationBar.backIndicatorImage = backImage
            navigationBar.backIndicatorTransitionMaskImage = backImage
        }
    }

    private func restoreBackButtonAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        if let previousNavigationBarTintColor {
            navigationBar.tintColor = previousNavigationBarTintColor
        }
        navigationBar.backIndicatorImage = previousBackIndicatorImage
        navigationBar.backIndicatorTransitionMaskImage = previousBackIndicatorTransitionMaskImage

        previousNavigationBarTintColor = nil
        previousBackIndicatorImage = nil
        previousBackIndicatorTransitionMaskImage = nil
    }

    // MARK: - Actions
    @objc
    private func handleAIReviewTap() {
        let content = InfoBottomSheetContent(
            title: UIConstants.aiReviewConfirmationTitle,
            description: UIConstants.aiReviewConfirmationDescription,
            buttonsConfiguration: .double(
                left: InfoBottomSheetAction(
                    identifier: .cancel,
                    title: "Отмена",
                    style: .buttonSecondary
                ),
                right: InfoBottomSheetAction(
                    identifier: .confirm,
                    title: "ОК",
                    style: .accentPrimary
                )
            )
        )

        showInfoBottomSheet(content) { [weak self] action in
            guard action == .confirm else {
                return
            }

            Task { [weak self] in
                await self?.interactor.handleAIReviewTap()
            }
        }
    }

    @objc
    private func handleGradeTap() {
        Task {
            await interactor.handleScoreInputCommit(scoreControlView.currentInputText)
            await interactor.handleGradeTap()
        }
    }

    @objc
    private func handlePreviousQuestionTap() {
        Task {
            await interactor.handlePreviousQuestionTap()
        }
    }

    @objc
    private func handleNextQuestionTap() {
        Task {
            await interactor.handleNextQuestionTap()
        }
    }

    @objc
    private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrameValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        let keyboardFrame = view.convert(keyboardFrameValue.cgRectValue, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
        let targetOffset = max(0, overlap - view.safeAreaInsets.bottom)
        keyboardBottomOffset = targetOffset
        bottomIslandBottomConstraint?.constant = -targetOffset

        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRawValue << 16)
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions) {
            self.view.layoutIfNeeded()
            self.updateTableInsetsForBottomIsland()
        }
    }

    @objc
    private func handleKeyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let animationCurveRawValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }

        keyboardBottomOffset = 0
        bottomIslandBottomConstraint?.constant = 0

        let animationOptions = UIView.AnimationOptions(rawValue: animationCurveRawValue << 16)
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationOptions) {
            self.view.layoutIfNeeded()
            self.updateTableInsetsForBottomIsland()
        }
    }
}

// MARK: - UITableViewDataSource
extension QuizParticipantReviewViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .header(let title):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: HeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title)
            return cell

        case .questionSwitcher(let items):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipantReviewQuestionSwitcherTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipantReviewQuestionSwitcherTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(items: items, selectedQuestionIndex: selectedQuestionIndex)
            cell.onQuestionTap = { [weak self] index in
                Task { [weak self] in
                    await self?.interactor.handleQuestionTap(index)
                }
            }
            return cell

        case .questionText(let text):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingQuestionTextTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingQuestionTextTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text)
            return cell

        case .openAnswer(let text):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingOpenAnswerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingOpenAnswerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text, isEditable: false, isLoading: false)
            return cell

        case .answerInfo(let viewData):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipantReviewAnswerInfoTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipantReviewAnswerInfoTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: viewData)
            return cell

        case .option(let viewData):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipantReviewOptionTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipantReviewOptionTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: viewData)
            return cell

        case .empty(let text):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyStateTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension QuizParticipantReviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .header:
            return 46
        case .questionSwitcher:
            return UIConstants.questionSwitcherRowHeight
        case .empty:
            return UITableView.automaticDimension
        case .questionText, .openAnswer, .answerInfo, .option:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .questionSwitcher:
            return UIConstants.questionSwitcherRowHeight
        case .questionText:
            return 80
        case .openAnswer:
            return 140
        case .answerInfo:
            return 90
        case .option:
            return 44
        case .empty:
            return 34
        case .header:
            return 46
        }
    }
}

// MARK: - InfoBottomSheetPresenting
extension QuizParticipantReviewViewController: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        self
    }
}
