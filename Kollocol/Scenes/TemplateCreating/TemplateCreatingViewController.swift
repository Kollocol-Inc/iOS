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
        table.allowsSelection = true
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
        static let validationErrorTitle = "Ошибка"
        static let titleRequiredMessage = "Укажите название шаблона"
        static let questionsRequiredMessage = "Недостаточно вопросов"
        static let deleteTemplateAlertTitle = "Удаление шаблона"
        static let deleteTemplateAlertMessage = "Вы уверены, что хотите удалить шаблон %@? Это действие необратимо"
        static let editUnsavedChangesAlertMessage = "Вы уверены, что хотите вернуться назад? Все изменения будут утеряны безвозвратно"
        static let createUnsavedChangesAlertMessage = "Вы уверены, что хотите выйти? Все изменения будут утеряны безвозвратно"
    }

    private struct QuestionSnapshot: Equatable {
        enum CorrectAnswer: Equatable {
            case none
            case openText(String)
            case singleChoice(Int)
            case multipleChoice([Int])
        }

        let id: String?
        let maxScore: Int?
        let options: [String]?
        let text: String?
        let timeLimitSec: Int?
        let type: QuestionType?
        let correctAnswer: CorrectAnswer
    }

    private struct TemplateStateSnapshot: Equatable {
        let title: String
        let quizType: QuizType
        let isRandomOrderEnabled: Bool
        let questions: [QuestionSnapshot]
    }

    // MARK: - Properties
    private var interactor: TemplateCreatingInteractor
    private let sourceTemplate: QuizTemplate?
    private let initialStateSnapshot: TemplateStateSnapshot

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
    private var deleteButtonItem: UIBarButtonItem?
    private var previousNavigationBarTintColor: UIColor?
    private var previousBackIndicatorImage: UIImage?
    private var previousBackIndicatorTransitionMaskImage: UIImage?

    private var isEditingTemplate: Bool {
        sourceTemplate != nil
    }

    private var editingTemplateId: String? {
        sourceTemplate?.id
    }

    // MARK: - Lifecycle
    init(
        interactor: TemplateCreatingInteractor,
        template: QuizTemplate? = nil,
        questions: [Question]? = nil
    ) {
        let templateQuestions = template?.questions ?? []
        let initialQuestions = templateQuestions.isEmpty ? (questions ?? []) : templateQuestions
        let initialTitle = template?.title
        let initialQuizType = template?.quizType ?? .async
        let initialRandomOrder = template?.settings?.randomOrder ?? false

        self.interactor = interactor
        self.sourceTemplate = template
        self.questions = initialQuestions
        self.titleText = initialTitle
        self.selectedQuizType = initialQuizType
        self.isRandomOrderEnabled = initialRandomOrder
        self.initialStateSnapshot = TemplateStateSnapshot(
            title: Self.normalizedTitle(initialTitle),
            quizType: initialQuizType,
            isRandomOrderEnabled: initialRandomOrder,
            questions: initialQuestions.map { Self.makeQuestionSnapshot(from: $0) }
        )
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
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreBackButtonAppearance()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }

    // MARK: - Methods
    @MainActor
    func displayCreateTemplateLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
        createButtonItem?.isEnabled = !isLoading
        deleteButtonItem?.isEnabled = !isLoading
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading

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
        navigationItem.hidesBackButton = true

        let backConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let backAction = UIAction { [weak self] _ in
            self?.handleBackTap()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward", withConfiguration: backConfiguration)?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: backAction
        )

        if isEditingTemplate {
            let deleteAction = UIAction { [weak self] _ in
                self?.handleDeleteTemplateTap()
            }
            let deleteConfiguration = UIImage.SymbolConfiguration(
                font: .systemFont(ofSize: 17, weight: .semibold)
            )
            let deleteBarButton = UIBarButtonItem(
                image: UIImage(systemName: "trash.fill", withConfiguration: deleteConfiguration)?
                    .withTintColor(.backgroundRedPrimary, renderingMode: .alwaysOriginal),
                primaryAction: deleteAction
            )

            let createAction = UIAction { [weak self] _ in
                self?.handleCreateButtonTap()
            }
            let checkmarkConfiguration = UIImage.SymbolConfiguration(
                font: .systemFont(ofSize: 17, weight: .semibold)
            )
            let saveBarButton = UIBarButtonItem(
                image: UIImage(systemName: "checkmark", withConfiguration: checkmarkConfiguration)?
                    .withTintColor(.backgroundGreen, renderingMode: .alwaysOriginal),
                primaryAction: createAction
            )

            createButtonItem = saveBarButton
            deleteButtonItem = deleteBarButton
            navigationItem.rightBarButtonItems = [saveBarButton, deleteBarButton]
        } else {
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
            deleteButtonItem = nil
            navigationItem.rightBarButtonItem = barButton
        }
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
        let normalizedTitle = Self.normalizedTitle(titleText)

        guard normalizedTitle.isEmpty == false else {
            showAlert(
                title: UIConstants.validationErrorTitle,
                message: UIConstants.titleRequiredMessage
            )
            return
        }

        guard questions.isEmpty == false else {
            showAlert(
                title: UIConstants.validationErrorTitle,
                message: UIConstants.questionsRequiredMessage
            )
            return
        }

        titleText = normalizedTitle
        selectedQuizType = settingsCell?.selectedQuizType ?? selectedQuizType
        isRandomOrderEnabled = settingsCell?.isRandomOrderEnabled ?? isRandomOrderEnabled

        let formData = TemplateCreatingModels.FormData(
            title: normalizedTitle,
            quizType: selectedQuizType,
            isRandomOrderEnabled: isRandomOrderEnabled,
            questions: questions
        )

        if isEditingTemplate {
            guard currentStateSnapshot != initialStateSnapshot else {
                navigationController?.popViewController(animated: true)
                return
            }

            guard let templateId = editingTemplateId else {
                showAlert(
                    title: UIConstants.validationErrorTitle,
                    message: "Не удалось определить шаблон для обновления"
                )
                return
            }

            Task {
                await interactor.updateTemplate(by: templateId, formData: formData)
            }
            return
        }

        Task {
            await interactor.createTemplate(formData: formData)
        }
    }

    private func handleBackTap() {
        guard hasUnsavedChanges else {
            navigationController?.popViewController(animated: true)
            return
        }

        let message = isEditingTemplate
            ? UIConstants.editUnsavedChangesAlertMessage
            : UIConstants.createUnsavedChangesAlertMessage

        showConfirmationAlert(
            title: "Внимание",
            message: message,
            cancelTitle: "Отмена",
            confirmTitle: "Выйти",
            confirmStyle: .destructive
        ) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
    }

    private func handleDeleteTemplateTap() {
        guard let templateId = editingTemplateId else { return }

        let templateTitle = Self.normalizedTitle(sourceTemplate?.title)
        let displayTitle = templateTitle.isEmpty ? "без названия" : "«\(templateTitle)»"
        let message = String(format: UIConstants.deleteTemplateAlertMessage, displayTitle)

        showConfirmationAlert(
            title: UIConstants.deleteTemplateAlertTitle,
            message: message,
            cancelTitle: "Отмена",
            confirmTitle: "Удалить",
            confirmStyle: .destructive
        ) { [weak self] in
            guard let self else { return }
            Task {
                await self.interactor.deleteTemplate(by: templateId)
            }
        }
    }

    private var hasUnsavedChanges: Bool {
        if isEditingTemplate {
            return currentStateSnapshot != initialStateSnapshot
        }

        let currentTitle = (nameInputCell?.currentText ?? titleText ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return currentTitle.isEmpty == false || questions.isEmpty == false
    }

    private var currentStateSnapshot: TemplateStateSnapshot {
        TemplateStateSnapshot(
            title: Self.normalizedTitle(nameInputCell?.currentText ?? titleText),
            quizType: settingsCell?.selectedQuizType ?? selectedQuizType,
            isRandomOrderEnabled: settingsCell?.isRandomOrderEnabled ?? isRandomOrderEnabled,
            questions: questions.map { Self.makeQuestionSnapshot(from: $0) }
        )
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
            visibleQuestions.enumerated().forEach { visibleIndex, item in
                newRows.append(
                    .question(
                        index: visibleIndex,
                        sourceIndex: item.sourceIndex,
                        question: item.question
                    )
                )
            }
        }

        newRows.append(.divider)
        newRows.append(.questionActions)

        rows = newRows
    }

    private func filteredQuestions() -> [(sourceIndex: Int, question: Question)] {
        let trimmedText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false else {
            return questions.enumerated().map { index, question in
                (sourceIndex: index, question: question)
            }
        }

        return questions.enumerated().compactMap { index, question in
            let matchesQuery = (question.text ?? "").localizedCaseInsensitiveContains(trimmedText)
            guard matchesQuery else { return nil }
            return (sourceIndex: index, question: question)
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
            self.questions.append(question)
            self.rebuildRows()
            self.tableView.reloadData()
        }

        presentQuestionBottomSheet(viewController)
    }

    private func handleEditQuestionTap(sourceIndex: Int) {
        guard questions.indices.contains(sourceIndex) else { return }

        let oldRows = rows
        let editingQuestion = questions[sourceIndex]
        let viewController = AddQuestionBottomSheetViewController(question: editingQuestion)
        viewController.onSaveQuestion = { [weak self] updatedQuestion in
            guard let self else { return }
            guard self.questions.indices.contains(sourceIndex) else { return }

            self.questions[sourceIndex] = updatedQuestion
            self.rebuildRows()
            self.reloadRowsAfterQuestionEdit(
                sourceIndex: sourceIndex,
                previousRows: oldRows
            )
        }

        presentQuestionBottomSheet(viewController)
    }

    private func handleDeleteQuestionTap(sourceIndex: Int) {
        guard questions.indices.contains(sourceIndex) else { return }

        showConfirmationAlert(
            title: "Удаление вопроса",
            message: "Вы уверены, что хотите удалить вопрос?",
            cancelTitle: "Отмена",
            confirmTitle: "Удалить",
            confirmStyle: .destructive
        ) { [weak self] in
            guard let self else { return }
            guard self.questions.indices.contains(sourceIndex) else { return }

            self.questions.remove(at: sourceIndex)
            self.rebuildRows()
            self.tableView.reloadData()
        }
    }

    private func presentQuestionBottomSheet(_ viewController: AddQuestionBottomSheetViewController) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        viewController.loadViewIfNeeded()
        if let sheet = navigationController.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let fitDetent = UISheetPresentationController.Detent.custom(
                    identifier: .init("add.question.bottom.sheet.fit")
                ) { [weak viewController] context in
                    guard let viewController else {
                        return context.maximumDetentValue * 0.75
                    }

                    let preferredHeight = viewController.preferredContentSize.height
                    if preferredHeight > 0 {
                        return min(preferredHeight, context.maximumDetentValue)
                    }

                    return viewController.preferredSheetHeight(
                        maximumDetentValue: context.maximumDetentValue
                    )
                }
                sheet.detents = [fitDetent]
            } else {
                sheet.detents = [.medium()]
            }
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }
        present(navigationController, animated: true)
    }

    private func reloadRowsAfterQuestionEdit(
        sourceIndex: Int,
        previousRows: [TemplateCreatingModels.Row]
    ) {
        let previousQuestionRowIndex = previousRows.firstIndex(where: { row in
            if case .question(_, let rowSourceIndex, _) = row {
                return rowSourceIndex == sourceIndex
            }
            return false
        })
        let updatedQuestionRowIndex = rows.firstIndex(where: { row in
            if case .question(_, let rowSourceIndex, _) = row {
                return rowSourceIndex == sourceIndex
            }
            return false
        })

        guard let previousQuestionRowIndex else { return }
        let previousQuestionIndexPath = IndexPath(row: previousQuestionRowIndex, section: 0)

        let updatedSummaryRowIndex = rows.firstIndex(where: { row in
            if case .questionsSummary = row { return true }
            return false
        })

        tableView.performBatchUpdates {
            switch updatedQuestionRowIndex {
            case .some(let updatedQuestionRowIndex):
                let updatedQuestionIndexPath = IndexPath(row: updatedQuestionRowIndex, section: 0)
                if updatedQuestionRowIndex == previousQuestionRowIndex {
                    tableView.reloadRows(at: [updatedQuestionIndexPath], with: .none)
                } else {
                    tableView.deleteRows(at: [previousQuestionIndexPath], with: .none)
                    tableView.insertRows(at: [updatedQuestionIndexPath], with: .none)
                }

            case .none:
                tableView.deleteRows(at: [previousQuestionIndexPath], with: .fade)
            }
        } completion: { [weak self] _ in
            guard let self else { return }
            guard let updatedSummaryRowIndex else { return }
            guard self.rows.indices.contains(updatedSummaryRowIndex) else { return }

            self.tableView.reloadRows(
                at: [IndexPath(row: updatedSummaryRowIndex, section: 0)],
                with: .none
            )
        }
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

    private static func normalizedTitle(_ title: String?) -> String {
        (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func makeQuestionSnapshot(from question: Question) -> QuestionSnapshot {
        let answerSnapshot: QuestionSnapshot.CorrectAnswer = {
            switch question.correctAnswer {
            case .openText(let value):
                return .openText(value)
            case .singleChoice(let index):
                return .singleChoice(index)
            case .multipleChoice(let indexes):
                return .multipleChoice(indexes)
            case .none:
                return .none
            }
        }()

        return QuestionSnapshot(
            id: question.id,
            maxScore: question.maxScore,
            options: question.options,
            text: question.text,
            timeLimitSec: question.timeLimitSec,
            type: question.type,
            correctAnswer: answerSnapshot
        )
    }
}

// MARK: - AlertPresenting
extension TemplateCreatingViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
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

        case .question(let index, let sourceIndex, let question):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TemplateQuestionCardTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TemplateQuestionCardTableViewCell else {
                return UITableViewCell()
            }

            let visibleQuestionsCount = filteredQuestions().count
            let isLastQuestion = index == visibleQuestionsCount - 1
            cell.configure(
                index: index,
                question: question,
                isLastQuestion: isLastQuestion
            )
            cell.onDeleteTap = { [weak self] in
                self?.handleDeleteQuestionTap(sourceIndex: sourceIndex)
            }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard rows.indices.contains(indexPath.row) else { return }
        guard case .question(_, let sourceIndex, _) = rows[indexPath.row] else { return }

        handleEditQuestionTap(sourceIndex: sourceIndex)
    }
}
