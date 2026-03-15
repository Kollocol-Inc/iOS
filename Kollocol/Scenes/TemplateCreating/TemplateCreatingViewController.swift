//
//  TemplateCreatingViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 14.03.2026.
//

import UIKit

final class TemplateCreatingViewController: UIViewController {
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
        table.allowsSelection = false
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let title = "Создание шаблона"
    }

    // MARK: - Properties
    private var interactor: TemplateCreatingInteractor
    private var rows: [TemplateCreatingModels.Row] = []
    private var questions: [Question]
    private var isAiButtonEnabled = true

    private var titleText: String?
    private var selectedQuizType: QuizType = .async
    private var isRandomOrderEnabled = false
    private var isLoading = false
    private var isSearchVisible = false
    private var searchText = ""
    private var shouldFocusSearchField = false

    private weak var nameInputCell: TextInputTableViewCell?
    private weak var settingsCell: TemplateSettingsTableViewCell?
    private var createButtonItem: UIBarButtonItem?
    private var previousNavigationBarTintColor: UIColor?
    private var previousBackIndicatorImage: UIImage?
    private var previousBackIndicatorTransitionMaskImage: UIImage?

    // MARK: - Lifecycle
    init(
        interactor: TemplateCreatingInteractor,
        questions: [Question]? = nil
    ) {
        self.interactor = interactor
        self.questions = questions ?? []
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        rebuildRows()
        configureUI()
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyBackButtonAppearance()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreBackButtonAppearance()
    }

    // MARK: - Methods
    @MainActor
    func displayCreateTemplateLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        createButtonItem?.isEnabled = !isLoading

        if isLoading {
            nameInputCell?.startAnimating()
        } else {
            nameInputCell?.stopAnimating()
        }

        if let nameInputCell {
            nameInputCell.configure(
                title: titleText,
                placeholder: "Введите название",
                isLoading: isLoading
            )
        }

        if let settingsCell {
            settingsCell.configure(
                quizType: selectedQuizType,
                isRandomOrderEnabled: isRandomOrderEnabled,
                isLoading: isLoading
            )
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
    }

    private func configureConstraints() {
        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinLeft(to: view.leadingAnchor)
        tableBackgroundView.pinRight(to: view.trailingAnchor)
        tableBackgroundView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 8)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: TextInputTableViewCell.reuseIdentifier)
        tableView.register(TemplateSettingsTableViewCell.self, forCellReuseIdentifier: TemplateSettingsTableViewCell.reuseIdentifier)
        tableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        tableView.register(TemplateQuestionActionsTableViewCell.self, forCellReuseIdentifier: TemplateQuestionActionsTableViewCell.reuseIdentifier)
        tableView.register(TemplateQuestionsInfoTableViewCell.self, forCellReuseIdentifier: TemplateQuestionsInfoTableViewCell.reuseIdentifier)
        tableView.register(TemplateQuestionsSearchTableViewCell.self, forCellReuseIdentifier: TemplateQuestionsSearchTableViewCell.reuseIdentifier)
        tableView.register(TemplateQuestionCardTableViewCell.self, forCellReuseIdentifier: TemplateQuestionCardTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = UIConstants.title
        titleLabel.textColor = .textSecondary
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        navigationItem.titleView = titleLabel

        let createAction = UIAction { [weak self] _ in
            self?.handleCreateButtonTap()
        }
        let checkmarkConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let barButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark", withConfiguration: checkmarkConfiguration)?
                .withTintColor(.backgroundGreen, renderingMode: .alwaysOriginal),
            primaryAction: createAction
        )

        createButtonItem = barButton
        navigationItem.rightBarButtonItem = barButton
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

    private func handleCreateButtonTap() {
        titleText = nameInputCell?.currentText ?? titleText
        selectedQuizType = settingsCell?.selectedQuizType ?? selectedQuizType
        isRandomOrderEnabled = settingsCell?.isRandomOrderEnabled ?? isRandomOrderEnabled

        let formData = TemplateCreatingModels.FormData(
            title: titleText,
            quizType: selectedQuizType,
            isRandomOrderEnabled: isRandomOrderEnabled,
            questions: questions
        )

        Task {
            await interactor.createTemplate(formData: formData)
        }
    }

    private func rebuildRows() {
        let visibleQuestions = filteredQuestions()

        var newRows: [TemplateCreatingModels.Row] = [
            .header("Название"),
            .nameInput,
            .header("Параметры"),
            .settings
        ]

        if questions.isEmpty == false {
            newRows.append(.divider)
            newRows.append(.questionsSummary)
            if isSearchVisible {
                newRows.append(.questionsSearch)
            }
            visibleQuestions.enumerated().forEach { index, question in
                newRows.append(.question(index: index, question: question))
            }
        }

        newRows.append(.divider)
        newRows.append(.questionActions)

        rows = newRows
    }

    private func filteredQuestions() -> [Question] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            return questions
        }

        return questions.filter { question in
            (question.text ?? "").localizedCaseInsensitiveContains(trimmedText)
        }
    }

    private func totalScore() -> Int {
        questions.reduce(0) { partialResult, question in
            partialResult + (question.maxScore ?? 0)
        }
    }

    private func totalTimeInSeconds() -> Int {
        questions.reduce(0) { partialResult, question in
            partialResult + (question.timeLimitSec ?? 0)
        }
    }

    private func totalTimeText() -> String {
        let seconds = totalTimeInSeconds()
        return "\(seconds)".asHmsFromSeconds() ?? "0 с."
    }

    private func handleAddQuestionTap() {
        let viewController = AddQuestionBottomSheetViewController()
        viewController.onSaveQuestion = { [weak self] question in
            guard let self else { return }
            let normalizedQuestion = Question(
                aiAnswer: question.aiAnswer,
                correctAnswer: question.correctAnswer,
                id: question.id,
                maxScore: question.maxScore,
                options: question.options,
                orderIndex: self.questions.count,
                text: question.text,
                timeLimitSec: question.timeLimitSec,
                type: question.type
            )
            self.questions.append(normalizedQuestion)
            self.rebuildRows()
            self.tableView.reloadData()
        }

        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }
        present(navigationController, animated: true)
    }

    private func handleCompleteWithAITap() {
    }

    private func toggleQuestionsSearch() {
        guard questions.isEmpty == false else { return }

        if isSearchVisible {
            view.endEditing(true)
            DispatchQueue.main.async { [weak self] in
                self?.performToggleQuestionsSearch()
            }
            return
        }

        performToggleQuestionsSearch()
    }

    private func performToggleQuestionsSearch() {
        guard questions.isEmpty == false else { return }

        let wasVisible = isSearchVisible
        let oldRows = rows

        isSearchVisible.toggle()
        if isSearchVisible {
            shouldFocusSearchField = false
        } else {
            shouldFocusSearchField = false
        }

        rebuildRows()

        let oldRowsCount = oldRows.count
        let newRowsCount = rows.count

        guard
            let oldSearchRowIndex = oldRows.firstIndex(where: { row in
                if case .questionsSearch = row { return true }
                return false
            }),
            wasVisible
        else {
            if let newSearchRowIndex = rows.firstIndex(where: { row in
                if case .questionsSearch = row { return true }
                return false
            }), newRowsCount == oldRowsCount + 1 {
                tableView.performBatchUpdates {
                    tableView.insertRows(at: [IndexPath(row: newSearchRowIndex, section: 0)], with: .automatic)
                } completion: { _ in
                    self.tableView.reloadData()
                }
            } else {
                tableView.reloadData()
            }
            return
        }

        if newRowsCount == oldRowsCount - 1 {
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [IndexPath(row: oldSearchRowIndex, section: 0)], with: .automatic)
            } completion: { _ in
                self.tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }

    private func handleSearchTextChanged(_ text: String) {
        searchText = text
        shouldFocusSearchField = false
        rebuildRows()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TemplateCreatingViewController: UITableViewDataSource {
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

        case .nameInput:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextInputTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TextInputTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: titleText,
                placeholder: "Введите название",
                isLoading: isLoading
            )
            cell.onTextChanged = { [weak self] newText in
                self?.titleText = newText
            }
            nameInputCell = cell
            return cell

        case .settings:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateSettingsTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateSettingsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                quizType: selectedQuizType,
                isRandomOrderEnabled: isRandomOrderEnabled,
                isLoading: isLoading
            )
            cell.onQuizTypeChanged = { [weak self] newValue in
                self?.selectedQuizType = newValue
            }
            cell.onRandomOrderChanged = { [weak self] newValue in
                self?.isRandomOrderEnabled = newValue
            }
            cell.onQuizTypeInfoTap = { [weak self] selectedType in
                guard let self else { return }
                Task {
                    await self.interactor.handleQuizTypeInfoTap(selectedType)
                }
            }
            settingsCell = cell
            return cell

        case .divider:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: DividerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? DividerTableViewCell else {
                return UITableViewCell()
            }

            return cell

        case .questionActions:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateQuestionActionsTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateQuestionActionsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(isAiButtonEnabled: isAiButtonEnabled)
            cell.onAddQuestionTap = { [weak self] in
                self?.handleAddQuestionTap()
            }
            cell.onCompleteWithAITap = { [weak self] in
                self?.handleCompleteWithAITap()
            }
            return cell

        case .questionsSummary:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateQuestionsInfoTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateQuestionsInfoTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                questionsCount: questions.count,
                totalScore: totalScore(),
                totalTimeText: totalTimeText(),
                isSearchVisible: isSearchVisible
            )
            cell.onAddQuestionTap = { [weak self] in
                self?.handleAddQuestionTap()
            }
            cell.onSearchToggleTap = { [weak self] in
                self?.toggleQuestionsSearch()
            }
            return cell

        case .questionsSearch:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateQuestionsSearchTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateQuestionsSearchTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                text: searchText,
                shouldFocus: shouldFocusSearchField
            )
            cell.onEditingDidEnd = { [weak self] newValue in
                self?.handleSearchTextChanged(newValue)
            }
            shouldFocusSearchField = false
            return cell

        case .question(let index, let question):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateQuestionCardTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateQuestionCardTableViewCell else {
                return UITableViewCell()
            }

            let visibleQuestions = filteredQuestions()
            guard visibleQuestions.indices.contains(index) else {
                return UITableViewCell()
            }

            let isLastQuestion = index == visibleQuestions.count - 1
            cell.configure(
                index: index,
                question: question,
                isLastQuestion: isLastQuestion
            )
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension TemplateCreatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .header:
            return 46
        case .nameInput:
            return UITableView.automaticDimension
        case .settings:
            return UITableView.automaticDimension
        case .divider:
            return 1
        case .questionActions:
            return UITableView.automaticDimension
        case .questionsSummary:
            return UITableView.automaticDimension
        case .questionsSearch:
            return UITableView.automaticDimension
        case .question:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .questionActions:
            return 74
        case .questionsSummary:
            return 66
        case .questionsSearch:
            return 60
        case .question:
            return 140
        case .settings:
            return 104
        default:
            return 44
        }
    }
}
