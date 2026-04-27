//
//  AddQuestionBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit
import QuartzCore

final class AddQuestionBottomSheetViewController: UIViewController {
    // MARK: - Typealias
    private enum QuestionMode: Int {
        case single
        case multi
        case openEnded

        var title: String {
            switch self {
            case .single:
                return "questionTypeSingleShort".localized
            case .multi:
                return "questionTypeMultiShort".localized
            case .openEnded:
                return "questionTypeOpenEndedShort".localized
            }
        }

        var questionType: QuestionType {
            switch self {
            case .single:
                return .singleChoice
            case .multi:
                return .multiChoice
            case .openEnded:
                return .openEnded
            }
        }
    }

    private struct OptionItem: Equatable {
        var text: String
        var isCorrect: Bool
    }

    private struct StateSnapshot: Equatable {
        let mode: QuestionMode
        let questionText: String
        let openAnswerText: String
        let score: Int
        let timeLimitSec: Int
        let options: [OptionItem]
    }

    private enum Row {
        case typePicker
        case header(String)
        case questionInput
        case paraphraseControls
        case parameters
        case divider
        case optionsHeader
        case option(index: Int)
        case openAnswer
    }

    // MARK: - UI Components
    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        return table
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let title = "addQuestion".localized
        static let maxOptionsCount = 10
        static let minOptionsCount = 2
        static let errorTitle = "errorTitle".localized
    }

    // MARK: - Properties
    var onSaveQuestion: ((Question) -> Void)?
    var onParaphraseQuestionText: ((String) async throws -> String)?

    private var rows: [Row] = []
    private var mode: QuestionMode = .single
    private var questionText: String = ""
    private var openAnswerText: String = ""
    private var score: Int = 1
    private var timeLimitSec: Int = 30
    private var options: [OptionItem] = []
    private let editingQuestionId: String?
    private let isEditingQuestion: Bool
    private let initialStateSnapshot: StateSnapshot

    private var saveButtonItem: UIBarButtonItem?
    private weak var activeTimePopoverController: AddQuestionTimePopoverViewController?
    private var lastMeasuredSheetHeight: CGFloat = 0
    private var keyboardBottomInset: CGFloat = 0
    private var paraphraseTask: Task<Void, Never>?
    private var isQuestionTextParaphrasing = false
    private var questionTextVariants: [String] = []
    private var currentQuestionTextVariantIndex: Int?

    // MARK: - Lifecycle
    init(question: Question? = nil) {
        let isEditingQuestion = question != nil
        let mode: QuestionMode = {
            switch question?.type {
            case .multiChoice:
                return .multi
            case .openEnded:
                return .openEnded
            case .singleChoice, .none:
                return .single
            }
        }()

        let questionText = question?.text ?? ""
        let openAnswerText: String = {
            guard case let .openText(value)? = question?.correctAnswer else { return "" }
            return value
        }()
        let score = question?.maxScore ?? 1
        let timeLimitSec = question?.timeLimitSec ?? 30
        let options: [OptionItem] = {
            guard mode != .openEnded else { return [] }

            let allOptions = question?.options ?? []
            let correctIndexes: Set<Int> = {
                switch question?.correctAnswer {
                case .singleChoice(let index):
                    return [index]
                case .multipleChoice(let indexes):
                    return Set(indexes)
                default:
                    return []
                }
            }()

            return allOptions.enumerated().map { index, option in
                OptionItem(
                    text: option,
                    isCorrect: correctIndexes.contains(index)
                )
            }
        }()

        self.mode = mode
        self.questionText = questionText
        self.openAnswerText = openAnswerText
        self.score = score
        self.timeLimitSec = timeLimitSec
        self.options = options
        self.editingQuestionId = question?.id
        self.isEditingQuestion = isEditingQuestion
        self.initialStateSnapshot = StateSnapshot(
            mode: mode,
            questionText: questionText,
            openAnswerText: openAnswerText,
            score: score,
            timeLimitSec: timeLimitSec,
            options: options
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
        configureKeyboardObservers()
        configureNavigationBar()
        updateSaveButtonState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.presentationController?.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        paraphraseTask?.cancel()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.backgroundColor = .backgroundSecondary
        configureConstraints()
        configureTableView()
    }

    private func configureConstraints() {
        view.addSubview(tableView)
        tableView.pin(to: view)
    }

    private func configureTableView() {
        tableView.register(AddQuestionTypePickerTableViewCell.self, forCellReuseIdentifier: AddQuestionTypePickerTableViewCell.reuseIdentifier)
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: TextInputTableViewCell.reuseIdentifier)
        tableView.register(AddQuestionParaphraseControlsTableViewCell.self, forCellReuseIdentifier: AddQuestionParaphraseControlsTableViewCell.reuseIdentifier)
        tableView.register(AddQuestionParametersTableViewCell.self, forCellReuseIdentifier: AddQuestionParametersTableViewCell.reuseIdentifier)
        tableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        tableView.register(AddQuestionHeaderWithButtonTableViewCell.self, forCellReuseIdentifier: AddQuestionHeaderWithButtonTableViewCell.reuseIdentifier)
        tableView.register(AddQuestionOptionTableViewCell.self, forCellReuseIdentifier: AddQuestionOptionTableViewCell.reuseIdentifier)
        tableView.register(AddQuestionOpenAnswerTableViewCell.self, forCellReuseIdentifier: AddQuestionOpenAnswerTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureNavigationBar() {
        navigationItem.title = UIConstants.title
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.textSecondary,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]

        let closeConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let closeAction = UIAction { [weak self] _ in
            self?.handleCloseTap()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark", withConfiguration: closeConfiguration)?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: closeAction
        )

        let saveConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let saveAction = UIAction { [weak self] _ in
            self?.handleSaveTap()
        }
        let saveButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark", withConfiguration: saveConfiguration)?
                .withTintColor(.backgroundGreen, renderingMode: .alwaysOriginal),
            primaryAction: saveAction
        )
        saveButtonItem = saveButton
        navigationItem.rightBarButtonItem = saveButton
    }

    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func preferredSheetHeight(maximumDetentValue: CGFloat) -> CGFloat {
        loadViewIfNeeded()
        view.layoutIfNeeded()

        let tableContentHeight = tableView.contentSize.height
        let navigationBarHeight = navigationController?.navigationBar.frame.height ?? 44
        let extraInsets = view.safeAreaInsets.top + view.safeAreaInsets.bottom + 12
        let measuredHeight = tableContentHeight + navigationBarHeight + extraInsets

        return min(max(measuredHeight, 220), maximumDetentValue)
    }

    private func rebuildRows() {
        var newRows: [Row] = [
            .typePicker,
            .header("question".localized),
            .questionInput,
            .paraphraseControls,
            .header("parameters".localized),
            .parameters,
            .divider
        ]

        switch mode {
        case .openEnded:
            newRows.append(.header("answerOptional".localized))
            newRows.append(.openAnswer)

        case .single, .multi:
            newRows.append(.optionsHeader)
            options.indices.forEach { index in
                newRows.append(.option(index: index))
            }
        }

        rows = newRows
    }

    private func updateSaveButtonState() {
        let isValid = validationErrorMessage == nil
        saveButtonItem?.isEnabled = true
        navigationItem.rightBarButtonItem?.tintColor = isValid
            ? .backgroundGreen
            : .backgroundGreen.withAlphaComponent(0.5)
    }

    private func handleModeChanged(_ newMode: QuestionMode) {
        guard mode != newMode else { return }

        let selectedIndexesBeforeModeChange = options.enumerated().compactMap { index, option in
            option.isCorrect ? index : nil
        }
        let oldRows = rows
        let oldMode = mode
        mode = newMode

        if newMode == .single, oldMode == .multi {
            options = options.map { .init(text: $0.text, isCorrect: false) }
        }

        if oldMode != .openEnded, newMode != .openEnded {
            if newMode == .single, oldMode == .multi {
                selectedIndexesBeforeModeChange.forEach { index in
                    animateOptionSwitchChange(at: index, isOn: false)
                }
            }
            updateSaveButtonState()
            return
        }

        rebuildRows()
        let oldDynamicRows = oldRows.indices
            .filter { $0 >= dynamicRowsStartIndex }
            .map { IndexPath(row: $0, section: 0) }
        let newDynamicRows = rows.indices
            .filter { $0 >= dynamicRowsStartIndex }
            .map { IndexPath(row: $0, section: 0) }

        tableView.performBatchUpdates {
            if oldDynamicRows.isEmpty == false {
                tableView.deleteRows(at: oldDynamicRows, with: .fade)
            }
            if newDynamicRows.isEmpty == false {
                tableView.insertRows(at: newDynamicRows, with: .fade)
            }
        } completion: { [weak self] _ in
            self?.updateSaveButtonState()
        }
    }

    private func handleAddOptionTap() {
        guard options.count < UIConstants.maxOptionsCount else { return }

        let oldRows = rows
        let newIndex = options.count
        options.append(.init(text: "", isCorrect: false))
        rebuildRows()

        guard
            let insertedRow = rows.firstIndex(where: { row in
                if case .option(let index) = row { return index == newIndex }
                return false
            })
        else {
            tableView.reloadData()
            updateSaveButtonState()
            return
        }

        tableView.performBatchUpdates {
            tableView.insertRows(at: [IndexPath(row: insertedRow, section: 0)], with: .automatic)
            if oldRows.count != rows.count {
                if let optionsHeaderIndex = rows.firstIndex(where: {
                    if case .optionsHeader = $0 { return true }
                    return false
                }) {
                    tableView.reloadRows(at: [IndexPath(row: optionsHeaderIndex, section: 0)], with: .none)
                }
            }
        } completion: { _ in
            self.updateSaveButtonState()
        }
    }

    private func handleDeleteOption(at index: Int) {
        guard options.indices.contains(index) else { return }
        options.remove(at: index)
        rebuildRows()
        tableView.reloadData()
        updateSaveButtonState()
    }

    private func handleOptionTextChanged(index: Int, text: String) {
        guard options.indices.contains(index) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let wasEmpty = options[index].text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        options[index].text = text

        if trimmed.isEmpty {
            options[index].isCorrect = false
        }

        let isEmpty = trimmed.isEmpty
        if wasEmpty != isEmpty {
            tableView.reloadRows(at: [IndexPath(row: indexPathForOption(index).row, section: 0)], with: .none)
        }

        updateSaveButtonState()
    }

    private func handleOptionToggleChanged(index: Int, isOn: Bool) {
        guard options.indices.contains(index) else { return }

        switch mode {
        case .single:
            let indexesToTurnOff = options.indices.filter {
                $0 != index && options[$0].isCorrect
            }
            if isOn {
                for itemIndex in options.indices {
                    options[itemIndex].isCorrect = itemIndex == index
                }
                indexesToTurnOff.forEach { optionIndex in
                    animateOptionSwitchChange(at: optionIndex, isOn: false)
                }
            } else {
                options[index].isCorrect = false
            }

        case .multi:
            options[index].isCorrect = isOn

        case .openEnded:
            break
        }

        updateSaveButtonState()
    }

    private func indexPathForOption(_ optionIndex: Int) -> IndexPath {
        let rowIndex = rows.firstIndex(where: { row in
            if case .option(let index) = row { return index == optionIndex }
            return false
        }) ?? 0
        return IndexPath(row: rowIndex, section: 0)
    }

    private func buildQuestion() -> Question {
        let normalizedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .openEnded:
            let normalizedOpenAnswer = openAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
            let correctAnswer: QuestionCorrectAnswer? = normalizedOpenAnswer.isEmpty
                ? nil
                : .openText(normalizedOpenAnswer)

            return Question(
                correctAnswer: correctAnswer,
                id: editingQuestionId,
                maxScore: score,
                options: nil,
                text: normalizedQuestion,
                timeLimitSec: timeLimitSec,
                type: .openEnded
            )

        case .single:
            let normalizedOptions = options.map {
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let selectedIndex = options.firstIndex(where: \.isCorrect)
            let correctAnswer = selectedIndex.map(QuestionCorrectAnswer.singleChoice)

            return Question(
                correctAnswer: correctAnswer,
                id: editingQuestionId,
                maxScore: score,
                options: normalizedOptions,
                text: normalizedQuestion,
                timeLimitSec: timeLimitSec,
                type: .singleChoice
            )

        case .multi:
            let normalizedOptions = options.map {
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let selectedIndexes = options.enumerated()
                .compactMap { index, option in
                    option.isCorrect ? index : nil
                }

            return Question(
                correctAnswer: .multipleChoice(selectedIndexes),
                id: editingQuestionId,
                maxScore: score,
                options: normalizedOptions,
                text: normalizedQuestion,
                timeLimitSec: timeLimitSec,
                type: .multiChoice
            )
        }
    }

    private func handleSaveTap() {
        if isQuestionTextParaphrasing {
            presentParaphrasingInProgressAlert()
            return
        }

        if isEditingQuestion, currentStateSnapshot == initialStateSnapshot {
            dismiss(animated: true)
            return
        }

        if let validationErrorMessage {
            showAlert(
                title: UIConstants.errorTitle,
                message: validationErrorMessage
            )
            return
        }

        onSaveQuestion?(buildQuestion())
        dismiss(animated: true)
    }

    private func handleCloseTap() {
        if isQuestionTextParaphrasing {
            presentParaphrasingInProgressAlert()
            return
        }

        guard shouldShowDiscardChangesAlert else {
            dismiss(animated: true)
            return
        }

        presentUnsavedChangesAlert()
    }

    private var shouldConfirmDismiss: Bool {
        isQuestionTextParaphrasing
            || shouldShowDiscardChangesAlert
    }

    private var shouldShowDiscardChangesAlert: Bool {
        if isEditingQuestion {
            return currentStateSnapshot != initialStateSnapshot
                || questionTextVariants.count > 1
        }

        return hasDraftDataForNewQuestion
    }

    private var hasDraftDataForNewQuestion: Bool {
        let normalizedQuestionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedQuestionText.isEmpty == false {
            return true
        }

        if options.isEmpty == false {
            return true
        }

        let normalizedOpenAnswerText = openAnswerText.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedOpenAnswerText.isEmpty == false {
            return true
        }

        if questionTextVariants.count > 1 {
            return true
        }

        if mode != initialStateSnapshot.mode {
            return true
        }

        if score != initialStateSnapshot.score || timeLimitSec != initialStateSnapshot.timeLimitSec {
            return true
        }

        return false
    }

    private var currentStateSnapshot: StateSnapshot {
        StateSnapshot(
            mode: mode,
            questionText: questionText,
            openAnswerText: openAnswerText,
            score: score,
            timeLimitSec: timeLimitSec,
            options: options
        )
    }

    private var validationErrorMessage: String? {
        let isQuestionFilled = questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        guard isQuestionFilled else {
            return "specifyQuestionText".localized
        }

        switch mode {
        case .openEnded:
            break
        case .single, .multi:
            if options.count < UIConstants.minOptionsCount {
                return "insufficientAnswerOptions".localized
            }

            let hasEmptyOption = options.contains {
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if hasEmptyOption {
                return "fillAllAnswerOptions".localized
            }

            let selectedCount = options.filter(\.isCorrect).count
            if selectedCount == 0 {
                switch mode {
                case .single:
                    return "specifyCorrectAnswerOption".localized
                case .multi:
                    return "specifyAtLeastOneCorrectAnswer".localized
                case .openEnded:
                    break
                }
            }
        }

        return nil
    }

    private func updatePreferredContentSizeIfNeeded() {
        let measuredHeight = preferredSheetHeight(maximumDetentValue: .greatestFiniteMagnitude)
        guard abs(lastMeasuredSheetHeight - measuredHeight) > 0.5 else { return }

        lastMeasuredSheetHeight = measuredHeight
        preferredContentSize = CGSize(width: view.bounds.width, height: measuredHeight)

        if #available(iOS 16.0, *) {
            navigationController?.sheetPresentationController?.invalidateDetents()
        }
    }

    private func applyKeyboardInset(
        _ bottomInset: CGFloat,
        duration: Double,
        options: UIView.AnimationOptions
    ) {
        keyboardBottomInset = max(0, bottomInset)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.tableView.contentInset.bottom = self.keyboardBottomInset
            self.tableView.verticalScrollIndicatorInsets.bottom = self.keyboardBottomInset
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollFirstResponderAboveKeyboard()
        }
    }

    private func scrollFirstResponderAboveKeyboard() {
        guard let firstResponder = findFirstResponder(in: tableView) else { return }
        let responderFrame = firstResponder.convert(firstResponder.bounds, to: tableView)
        tableView.scrollRectToVisible(responderFrame.insetBy(dx: 0, dy: -12), animated: true)
    }

    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }

        for subview in view.subviews {
            if let responder = findFirstResponder(in: subview) {
                return responder
            }
        }

        return nil
    }

    private var hasParaphraseHistory: Bool {
        questionTextVariants.count > 1 && currentQuestionTextVariantIndex != nil
    }

    private var canMoveQuestionTextBackward: Bool {
        guard let currentQuestionTextVariantIndex else { return false }
        return currentQuestionTextVariantIndex > 0
    }

    private var canMoveQuestionTextForward: Bool {
        guard let currentQuestionTextVariantIndex else { return false }
        return currentQuestionTextVariantIndex < questionTextVariants.count - 1
    }

    private func handleQuestionTextChanged(_ text: String) {
        questionText = text

        if
            let currentQuestionTextVariantIndex,
            questionTextVariants.indices.contains(currentQuestionTextVariantIndex)
        {
            questionTextVariants[currentQuestionTextVariantIndex] = text
            reloadParaphraseControlsRow()
        }

        updateSaveButtonState()
    }

    private func handleQuestionParaphraseTap() {
        guard isQuestionTextParaphrasing == false else { return }

        let normalizedQuestionText = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuestionText.isEmpty == false else { return }
        guard let onParaphraseQuestionText else { return }

        showConfirmationAlert(
            title: "confirmationTitle".localized,
            message: "confirmParaphraseQuestionText".localized,
            cancelTitle: "cancel".localized,
            confirmTitle: "paraphrase".localized,
            confirmStyle: .default
        ) { [weak self] in
            self?.startParaphrasingQuestionText(
                normalizedQuestionText,
                using: onParaphraseQuestionText
            )
        }
    }

    private func startParaphrasingQuestionText(
        _ normalizedQuestionText: String,
        using onParaphraseQuestionText: @escaping (String) async throws -> String
    ) {
        let previousQuestionText = questionText

        if
            let currentQuestionTextVariantIndex,
            questionTextVariants.indices.contains(currentQuestionTextVariantIndex)
        {
            questionTextVariants[currentQuestionTextVariantIndex] = previousQuestionText
        }

        isQuestionTextParaphrasing = true
        reloadQuestionInputAndParaphraseRows()

        paraphraseTask?.cancel()
        paraphraseTask = Task { [weak self] in
            guard let self else { return }

            do {
                let paraphrasedQuestionText = try await onParaphraseQuestionText(normalizedQuestionText)
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    if self.currentQuestionTextVariantIndex == nil || self.questionTextVariants.isEmpty {
                        self.questionTextVariants = [previousQuestionText, paraphrasedQuestionText]
                        self.currentQuestionTextVariantIndex = 1
                    } else {
                        self.questionTextVariants.append(paraphrasedQuestionText)
                        self.currentQuestionTextVariantIndex = self.questionTextVariants.count - 1
                    }

                    self.questionText = paraphrasedQuestionText
                    self.isQuestionTextParaphrasing = false
                    self.reloadQuestionInputAndParaphraseRows()
                    self.updateSaveButtonState()
                }
            } catch is CancellationError {
                await MainActor.run {
                    self.isQuestionTextParaphrasing = false
                    self.reloadQuestionInputAndParaphraseRows()
                }
            } catch {
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    self.isQuestionTextParaphrasing = false
                    self.reloadQuestionInputAndParaphraseRows()
                    self.showAlert(
                        title: UIConstants.errorTitle,
                        message: (error as? any UserFacingError)?.userMessage ?? "somethingWentWrong".localized
                    )
                }
            }

            await MainActor.run {
                self.paraphraseTask = nil
            }
        }
    }

    private func handleQuestionTextBackwardTap() {
        guard isQuestionTextParaphrasing == false else { return }
        guard canMoveQuestionTextBackward else { return }
        guard let currentQuestionTextVariantIndex else { return }

        let nextIndex = currentQuestionTextVariantIndex - 1
        guard questionTextVariants.indices.contains(nextIndex) else { return }

        self.currentQuestionTextVariantIndex = nextIndex
        questionText = questionTextVariants[nextIndex]
        reloadQuestionInputAndParaphraseRows()
        updateSaveButtonState()
    }

    private func handleQuestionTextForwardTap() {
        guard isQuestionTextParaphrasing == false else { return }
        guard canMoveQuestionTextForward else { return }
        guard let currentQuestionTextVariantIndex else { return }

        let nextIndex = currentQuestionTextVariantIndex + 1
        guard questionTextVariants.indices.contains(nextIndex) else { return }

        self.currentQuestionTextVariantIndex = nextIndex
        questionText = questionTextVariants[nextIndex]
        reloadQuestionInputAndParaphraseRows()
        updateSaveButtonState()
    }

    private func reloadQuestionInputAndParaphraseRows() {
        reloadQuestionInputRow()
        reloadParaphraseControlsRow()
    }

    private func reloadQuestionInputRow() {
        guard let rowIndex = rows.firstIndex(where: {
            if case .questionInput = $0 { return true }
            return false
        }) else {
            return
        }

        tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .none)
    }

    private func reloadParaphraseControlsRow() {
        guard let rowIndex = rows.firstIndex(where: {
            if case .paraphraseControls = $0 { return true }
            return false
        }) else {
            return
        }

        tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .none)
    }

    private func presentParaphrasingInProgressAlert() {
        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: "confirmExitQuestionTextGenerationInProgress".localized,
            cancelTitle: "cancel".localized,
            confirmTitle: "exit".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            self?.paraphraseTask?.cancel()
            self?.dismiss(animated: true)
        }
    }

    private func presentUnsavedChangesAlert() {
        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: "confirmExitUnsavedChanges".localized,
            cancelTitle: "cancel".localized,
            confirmTitle: "exit".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let change = KeyboardChange(notification) else { return }

        let keyboardFrame = view.convert(change.endFrame, from: nil)
        let keyboardTop = keyboardFrame.minY
        let safeAreaBottom = view.safeAreaLayoutGuide.layoutFrame.maxY
        let lift = max(0, safeAreaBottom - keyboardTop)

        applyKeyboardInset(lift, duration: change.duration, options: change.options)
    }

}

// MARK: - AlertPresenting
extension AddQuestionBottomSheetViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AddQuestionBottomSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        shouldConfirmDismiss == false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        handleCloseTap()
    }
}

// MARK: - UITableViewDataSource
extension AddQuestionBottomSheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .typePicker:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionTypePickerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionTypePickerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(selectedIndex: mode.rawValue)
            cell.onModeChanged = { [weak self] selectedIndex in
                guard let mode = QuestionMode(rawValue: selectedIndex) else { return }
                self?.handleModeChanged(mode)
            }
            return cell

        case .header(let title):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: HeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title)
            return cell

        case .questionInput:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextInputTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TextInputTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: questionText,
                placeholder: "enterQuestionPlaceholder".localized,
                isLoading: isQuestionTextParaphrasing
            )
            cell.onTextChanged = { [weak self] text in
                self?.handleQuestionTextChanged(text)
            }
            return cell

        case .paraphraseControls:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionParaphraseControlsTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionParaphraseControlsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                mode: hasParaphraseHistory
                    ? .history
                    : .initial,
                canMoveBackward: canMoveQuestionTextBackward,
                canMoveForward: canMoveQuestionTextForward,
                isLoading: isQuestionTextParaphrasing
            )
            cell.onInitialParaphraseTap = { [weak self] in
                self?.handleQuestionParaphraseTap()
            }
            cell.onHistoryBackwardTap = { [weak self] in
                self?.handleQuestionTextBackwardTap()
            }
            cell.onHistoryForwardTap = { [weak self] in
                self?.handleQuestionTextForwardTap()
            }
            cell.onHistoryParaphraseTap = { [weak self] in
                self?.handleQuestionParaphraseTap()
            }
            return cell

        case .parameters:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionParametersTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionParametersTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                score: score,
                timeLimitSec: timeLimitSec
            )
            cell.onScoreChanged = { [weak self] value in
                self?.score = value
            }
            cell.onTimeTap = { [weak self] sourceView in
                self?.presentTimePopover(from: sourceView)
            }
            return cell

        case .divider:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: DividerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? DividerTableViewCell else {
                return UITableViewCell()
            }

            return cell

        case .optionsHeader:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionHeaderWithButtonTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionHeaderWithButtonTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: "answers".localized,
                isAddButtonHidden: options.count >= UIConstants.maxOptionsCount
            )
            cell.onAddTap = { [weak self] in
                self?.handleAddOptionTap()
            }
            return cell

        case .option(let index):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionOptionTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionOptionTableViewCell else {
                return UITableViewCell()
            }

            guard options.indices.contains(index) else {
                return UITableViewCell()
            }

            let item = options[index]
            cell.configure(
                text: item.text,
                isSwitchOn: item.isCorrect,
                isSwitchEnabled: item.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            )
            cell.onTextChanged = { [weak self] text in
                self?.handleOptionTextChanged(index: index, text: text)
            }
            cell.onToggleChanged = { [weak self] isOn in
                self?.handleOptionToggleChanged(index: index, isOn: isOn)
            }
            cell.onDeleteTap = { [weak self] in
                self?.handleDeleteOption(at: index)
            }
            return cell

        case .openAnswer:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: AddQuestionOpenAnswerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? AddQuestionOpenAnswerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: openAnswerText)
            cell.onTextChanged = { [weak self] text in
                self?.openAnswerText = text
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension AddQuestionBottomSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .typePicker:
            return 50
        case .header:
            return 46
        case .questionInput:
            return UITableView.automaticDimension
        case .paraphraseControls:
            return 50
        case .parameters:
            return UITableView.automaticDimension
        case .divider:
            return 1
        case .optionsHeader:
            return 46
        case .option:
            return 52
        case .openAnswer:
            return 136
        }
    }
}

// MARK: - UIPopoverPresentationControllerDelegate
extension AddQuestionBottomSheetViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}

private extension AddQuestionBottomSheetViewController {
    func presentTimePopover(from sourceView: UIView) {
        if let activeTimePopoverController {
            activeTimePopoverController.dismiss(animated: false)
        }

        let controller = AddQuestionTimePopoverViewController(
            selectedTotalSeconds: timeLimitSec
        )
        controller.onApply = { [weak self] selectedTotalSeconds in
            guard let self else { return }
            self.timeLimitSec = selectedTotalSeconds
            self.updateSaveButtonState()
            self.tableView.reloadRows(
                at: [IndexPath(row: self.parametersRowIndex, section: 0)],
                with: .none
            )
        }
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.delegate = self
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        controller.popoverPresentationController?.sourceView = sourceView
        controller.popoverPresentationController?.sourceRect = sourceView.bounds
        activeTimePopoverController = controller
        present(controller, animated: true)
    }

    var parametersRowIndex: Int {
        rows.firstIndex(where: { row in
            if case .parameters = row { return true }
            return false
        }) ?? 0
    }

    var dynamicRowsStartIndex: Int {
        7
    }

    func animateOptionSwitchChange(at optionIndex: Int, isOn: Bool) {
        let indexPath = indexPathForOption(optionIndex)
        guard
            let cell = tableView.cellForRow(at: indexPath) as? AddQuestionOptionTableViewCell
        else {
            return
        }

        cell.setSwitch(isOn: isOn, animated: true)
    }
}

private final class AddQuestionTypePickerTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            "questionTypeSingleShort".localized,
            "questionTypeMultiShort".localized,
            "questionTypeOpenEndedShort".localized
        ])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .backgroundSecondary
        control.layer.cornerRadius = 12
        control.clipsToBounds = true
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.controlUnselected,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ],
            for: .normal
        )
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.controlSelected,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ],
            for: .selected
        )
        return control
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionTypePickerTableViewCell"

    // MARK: - Properties
    var onModeChanged: ((Int) -> Void)?

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(selectedIndex: Int) {
        segmentedControl.selectedSegmentIndex = selectedIndex
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(segmentedControl)
        segmentedControl.pinCenterY(to: contentView)
        segmentedControl.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        segmentedControl.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        segmentedControl.setHeight(36)

        segmentedControl.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)
    }

    // MARK: - Actions
    @objc
    private func handleValueChanged() {
        onModeChanged?(segmentedControl.selectedSegmentIndex)
    }
}

private final class AddQuestionParaphraseControlsTableViewCell: UITableViewCell {
    // MARK: - Typealias
    enum Mode {
        case initial
        case history
    }

    // MARK: - UI Components
    private let initialParaphraseButton = UIButton(type: .system)
    private let historyBackwardButton = UIButton(type: .system)
    private let historyForwardButton = UIButton(type: .system)
    private let historyParaphraseButton = UIButton(type: .system)

    private let historyButtonsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionParaphraseControlsTableViewCell"

    // MARK: - Properties
    var onInitialParaphraseTap: (() -> Void)?
    var onHistoryBackwardTap: (() -> Void)?
    var onHistoryForwardTap: (() -> Void)?
    var onHistoryParaphraseTap: (() -> Void)?

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
        onInitialParaphraseTap = nil
        onHistoryBackwardTap = nil
        onHistoryForwardTap = nil
        onHistoryParaphraseTap = nil
    }

    // MARK: - Methods
    func configure(
        mode: Mode,
        canMoveBackward: Bool,
        canMoveForward: Bool,
        isLoading: Bool
    ) {
        switch mode {
        case .initial:
            initialParaphraseButton.isHidden = false
            historyButtonsStackView.isHidden = true
            applyState(
                button: initialParaphraseButton,
                isEnabled: isLoading == false
            )
        case .history:
            initialParaphraseButton.isHidden = true
            historyButtonsStackView.isHidden = false
            applyState(
                button: historyBackwardButton,
                isEnabled: isLoading == false && canMoveBackward
            )
            applyState(
                button: historyForwardButton,
                isEnabled: isLoading == false && canMoveForward
            )
            applyState(
                button: historyParaphraseButton,
                isEnabled: isLoading == false
            )
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        configureButtons()
        configureConstraints()
        configureActions()
    }

    private func configureButtons() {
        styleActionButton(initialParaphraseButton)
        styleActionButton(historyBackwardButton)
        styleActionButton(historyForwardButton)
        styleActionButton(historyParaphraseButton)

        setupButton(
            initialParaphraseButton,
            symbolName: "wand.and.sparkles.inverse",
            title: "paraphrase".localized
        )
        setupButton(
            historyBackwardButton,
            symbolName: "arrow.uturn.left",
            title: nil
        )
        setupButton(
            historyForwardButton,
            symbolName: "arrow.uturn.forward",
            title: nil
        )
        setupButton(
            historyParaphraseButton,
            symbolName: "wand.and.sparkles.inverse",
            title: "ai".localized
        )
    }

    private func configureConstraints() {
        contentView.addSubview(initialParaphraseButton)
        initialParaphraseButton.pinTop(to: contentView.topAnchor, 8)
        initialParaphraseButton.pinBottom(to: contentView.bottomAnchor)
        initialParaphraseButton.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        initialParaphraseButton.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        contentView.addSubview(historyButtonsStackView)
        historyButtonsStackView.pinTop(to: contentView.topAnchor, 8)
        historyButtonsStackView.pinBottom(to: contentView.bottomAnchor)
        historyButtonsStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        historyButtonsStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        historyButtonsStackView.addArrangedSubview(historyBackwardButton)
        historyButtonsStackView.addArrangedSubview(historyForwardButton)
        historyButtonsStackView.addArrangedSubview(historyParaphraseButton)
    }

    private func configureActions() {
        initialParaphraseButton.addTarget(self, action: #selector(handleInitialParaphraseTap), for: .touchUpInside)
        historyBackwardButton.addTarget(self, action: #selector(handleHistoryBackwardTap), for: .touchUpInside)
        historyForwardButton.addTarget(self, action: #selector(handleHistoryForwardTap), for: .touchUpInside)
        historyParaphraseButton.addTarget(self, action: #selector(handleHistoryParaphraseTap), for: .touchUpInside)
    }

    private func styleActionButton(_ button: UIButton) {
        button.backgroundColor = .clear
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.buttonSecondary.cgColor
        button.clipsToBounds = true
        button.setHeight(42)
    }

    private func setupButton(
        _ button: UIButton,
        symbolName: String,
        title: String?
    ) {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: symbolName)?
            .withTintColor(.buttonSecondary, renderingMode: .alwaysOriginal)
        configuration.imagePadding = title == nil ? 0 : 6
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)

        if let title {
            var attributedTitle = AttributedString(title)
            attributedTitle.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            attributedTitle.foregroundColor = .buttonSecondary
            configuration.attributedTitle = attributedTitle
        }

        button.configuration = configuration
    }

    private func applyState(button: UIButton, isEnabled: Bool) {
        button.isEnabled = isEnabled
        button.alpha = isEnabled ? 1 : 0.45
    }

    // MARK: - Actions
    @objc
    private func handleInitialParaphraseTap() {
        onInitialParaphraseTap?()
    }

    @objc
    private func handleHistoryBackwardTap() {
        onHistoryBackwardTap?()
    }

    @objc
    private func handleHistoryForwardTap() {
        onHistoryForwardTap?()
    }

    @objc
    private func handleHistoryParaphraseTap() {
        onHistoryParaphraseTap?()
    }
}

private final class AddQuestionParametersTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let scoreTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "score".localized
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let scoreCapsuleView: UIView = {
        let view = UIView()
        view.backgroundColor = .accentPrimary
        view.layer.cornerRadius = 17
        return view
    }()

    private let scoreMinusButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 16, weight: .regular)
        )
        let image = UIImage(systemName: "minus", withConfiguration: configuration)?
            .withTintColor(.textWhite, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium)
        label.textColor = .textWhite
        label.textAlignment = .center
        return label
    }()

    private let scorePlusButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 16, weight: .regular)
        )
        let image = UIImage(systemName: "plus", withConfiguration: configuration)?
            .withTintColor(.textWhite, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let scoreStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.spacing = 8
        return stack
    }()

    private let timeTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "time".localized
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private let timeCapsuleButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 17
        button.setHeight(34)
        button.contentHorizontalAlignment = .center
        return button
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textColor = .textWhite
        label.textAlignment = .center
        return label
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionParametersTableViewCell"

    // MARK: - Properties
    var onScoreChanged: ((Int) -> Void)?
    var onTimeTap: ((UIView) -> Void)?
    private var score: Int = 1
    private var timeLimitSec: Int = 30

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
        onTimeTap = nil
    }

    // MARK: - Methods
    func configure(score: Int, timeLimitSec: Int) {
        self.score = max(1, score)
        scoreLabel.text = "\(self.score)"
        updateMinusButtonState()
        self.timeLimitSec = max(0, timeLimitSec)
        timeLabel.text = formatTime(self.timeLimitSec)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(scoreTitleLabel)
        scoreTitleLabel.pinTop(to: contentView.topAnchor, 8)
        scoreTitleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 40)

        contentView.addSubview(scoreCapsuleView)
        scoreCapsuleView.pinCenterY(to: scoreTitleLabel)
        scoreCapsuleView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        scoreCapsuleView.setHeight(34)

        scoreCapsuleView.addSubview(scoreStackView)
        scoreStackView.pinTop(to: scoreCapsuleView.topAnchor, 6)
        scoreStackView.pinBottom(to: scoreCapsuleView.bottomAnchor, 6)
        scoreStackView.pinLeft(to: scoreCapsuleView.leadingAnchor, 11)
        scoreStackView.pinRight(to: scoreCapsuleView.trailingAnchor, 11)

        scoreStackView.addArrangedSubview(scoreMinusButton)
        scoreStackView.addArrangedSubview(scoreLabel)
        scoreStackView.addArrangedSubview(scorePlusButton)

        contentView.addSubview(timeTitleLabel)
        timeTitleLabel.pinTop(to: scoreTitleLabel.bottomAnchor, 24)
        timeTitleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 40)
        timeTitleLabel.pinBottom(to: contentView.bottomAnchor, 16)

        contentView.addSubview(timeCapsuleButton)
        timeCapsuleButton.pinCenterY(to: timeTitleLabel)
        timeCapsuleButton.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        timeCapsuleButton.addSubview(timeLabel)
        timeLabel.pinTop(to: timeCapsuleButton.topAnchor, 6)
        timeLabel.pinBottom(to: timeCapsuleButton.bottomAnchor, 6)
        timeLabel.pinLeft(to: timeCapsuleButton.leadingAnchor, 11)
        timeLabel.pinRight(to: timeCapsuleButton.trailingAnchor, 11)

        scoreMinusButton.addTarget(self, action: #selector(handleMinusTap), for: .touchUpInside)
        scorePlusButton.addTarget(self, action: #selector(handlePlusTap), for: .touchUpInside)
        timeCapsuleButton.addTarget(self, action: #selector(handleTimeTap), for: .touchUpInside)
    }

    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = max(0, totalSeconds / 60)
        let seconds = max(0, totalSeconds % 60)
        return String(format: "timeMinutesSecondsFormat".localized, minutes, seconds)
    }

    // MARK: - Actions
    @objc
    private func handleMinusTap() {
        guard score > 1 else { return }
        let previousValue = score
        score -= 1
        animateScoreLabelTransition(
            from: previousValue,
            to: score
        )
        updateMinusButtonState()
        onScoreChanged?(score)
    }

    @objc
    private func handlePlusTap() {
        let previousValue = score
        score += 1
        animateScoreLabelTransition(
            from: previousValue,
            to: score
        )
        updateMinusButtonState()
        onScoreChanged?(score)
    }

    @objc
    private func handleTimeTap() {
        onTimeTap?(timeCapsuleButton)
    }

    private func animateScoreLabelTransition(from oldValue: Int, to newValue: Int) {
        let transition = CATransition()
        transition.type = .push
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.subtype = newValue > oldValue ? .fromBottom : .fromTop
        scoreLabel.layer.add(transition, forKey: "scoreChangePush")
        scoreLabel.text = "\(newValue)"
    }

    private func updateMinusButtonState() {
        scoreMinusButton.alpha = score <= 1 ? 0.5 : 1.0
    }

}

private final class AddQuestionTimePopoverViewController: UIViewController {
    // MARK: - UI Components
    private let pickerView = UIPickerView()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("save".localized, for: .normal)
        button.setTitleColor(.accentPrimary, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let minValue = 0
        static let maxValue = 59
        static let componentCount = 2
    }

    // MARK: - Properties
    var onApply: ((Int) -> Void)?

    private var selectedMinutes: Int
    private var selectedSeconds: Int

    // MARK: - Lifecycle
    init(selectedTotalSeconds: Int) {
        let normalized = max(0, selectedTotalSeconds)
        selectedMinutes = min(UIConstants.maxValue, normalized / 60)
        selectedSeconds = min(UIConstants.maxValue, normalized % 60)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.backgroundColor = .backgroundSecondary
        preferredContentSize = CGSize(width: 250, height: 230)

        view.addSubview(pickerView)
        pickerView.pinTop(to: view.topAnchor, 8)
        pickerView.pinHorizontal(to: view, 8)
        pickerView.setHeight(170)

        view.addSubview(doneButton)
        doneButton.pinTop(to: pickerView.bottomAnchor, 4)
        doneButton.pinCenterX(to: view)
        doneButton.pinBottom(to: view.bottomAnchor, 8)

        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedMinutes, inComponent: 0, animated: false)
        pickerView.selectRow(selectedSeconds, inComponent: 1, animated: false)

        doneButton.addTarget(self, action: #selector(handleDoneTap), for: .touchUpInside)
    }

    private func timeString(for value: Int, unit: String) -> String {
        String(format: "%02d %@", value, unit)
    }

    // MARK: - Actions
    @objc
    private func handleDoneTap() {
        onApply?(selectedMinutes * 60 + selectedSeconds)
        dismiss(animated: true)
    }
}

// MARK: - UIPickerViewDataSource
extension AddQuestionTimePopoverViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        UIConstants.componentCount
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        UIConstants.maxValue - UIConstants.minValue + 1
    }
}

// MARK: - UIPickerViewDelegate
extension AddQuestionTimePopoverViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return timeString(for: row, unit: "minuteShortSingle".localized)
        }
        return timeString(for: row, unit: "secondShortSingle".localized)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            selectedMinutes = row
        } else {
            selectedSeconds = row
        }
    }
}

private final class AddQuestionHeaderWithButtonTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return label
    }()

    private let addButtonContainerView: UIView = {
        let view = UIView()
        view.setWidth(34)
        view.setHeight(34)
        return view
    }()

    private let addButtonGlassBackgroundView: UIVisualEffectView = {
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 12, weight: .semibold)
        )
        let image = UIImage(systemName: "plus", withConfiguration: symbolConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionHeaderWithButtonTableViewCell"

    // MARK: - Properties
    var onAddTap: (() -> Void)?

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
        onAddTap = nil
    }

    // MARK: - Methods
    func configure(title: String, isAddButtonHidden: Bool) {
        titleLabel.text = title
        addButtonContainerView.isHidden = isAddButtonHidden
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(titleLabel)
        titleLabel.pinTop(to: contentView.topAnchor)
        titleLabel.pinBottom(to: contentView.bottomAnchor)
        titleLabel.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)

        contentView.addSubview(addButtonContainerView)
        addButtonContainerView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        addButtonContainerView.pinCenterY(to: titleLabel)

        addButtonContainerView.addSubview(addButtonGlassBackgroundView)
        addButtonGlassBackgroundView.pin(to: addButtonContainerView)
        configureGlassBackgroundView(addButtonGlassBackgroundView)

        addButtonGlassBackgroundView.contentView.addSubview(addButton)
        addButton.pin(to: addButtonGlassBackgroundView.contentView)
        addButton.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)
    }

    private func configureGlassBackgroundView(_ view: UIVisualEffectView) {
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = 17
        view.layer.cornerCurve = .continuous
    }

    // MARK: - Actions
    @objc
    private func handleAddTap() {
        onAddTap?()
    }
}

private final class AddQuestionOptionTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let optionTextField: UITextField = {
        let field = UITextField()
        field.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        field.textColor = .textSecondary
        field.attributedPlaceholder = NSAttributedString(
            string: "enterAnswerPlaceholder".localized,
            attributes: [
                .foregroundColor: UIColor.dividerPrimary,
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ]
        )
        field.borderStyle = .none
        return field
    }()

    private let toggleSwitch: UISwitch = {
        let control = UISwitch()
        control.onTintColor = .accentPrimary
        return control
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionOptionTableViewCell"

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?
    var onToggleChanged: ((Bool) -> Void)?
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
        onTextChanged = nil
        onToggleChanged = nil
        onDeleteTap = nil
    }

    // MARK: - Methods
    func configure(text: String, isSwitchOn: Bool, isSwitchEnabled: Bool) {
        optionTextField.text = text
        toggleSwitch.isOn = isSwitchOn
        toggleSwitch.isEnabled = isSwitchEnabled
    }

    func setSwitch(isOn: Bool, animated: Bool) {
        guard toggleSwitch.isOn != isOn else { return }
        toggleSwitch.setOn(isOn, animated: animated)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(contentStackView)
        contentStackView.pinTop(to: contentView.topAnchor)
        contentStackView.pinBottom(to: contentView.bottomAnchor)
        contentStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 40)
        contentStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)

        contentStackView.addArrangedSubview(optionTextField)
        contentStackView.addArrangedSubview(toggleSwitch)
        optionTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        optionTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        toggleSwitch.setContentHuggingPriority(.required, for: .horizontal)
        toggleSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)

        optionTextField.delegate = self
        toggleSwitch.addTarget(self, action: #selector(handleSwitchChanged), for: .valueChanged)

        let contextInteraction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(contextInteraction)
    }

    // MARK: - Actions
    @objc
    private func handleSwitchChanged() {
        onToggleChanged?(toggleSwitch.isOn)
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension AddQuestionOptionTableViewCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(
            identifier: nil,
            previewProvider: nil
        ) { [weak self] _ in
            let delete = UIAction(
                title: "delete".localized,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.onDeleteTap?()
            }

            return UIMenu(children: [delete])
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddQuestionOptionTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        onTextChanged?(textField.text ?? "")
    }
}

private final class AddQuestionOpenAnswerTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let textView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .dividerPrimary
        textView.layer.cornerRadius = 18
        textView.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        textView.textColor = .textSecondary
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        return textView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "AddQuestionOpenAnswerTableViewCell"

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?

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
        onTextChanged = nil
    }

    // MARK: - Methods
    func configure(text: String) {
        textView.text = text
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(textView)
        textView.pinTop(to: contentView.topAnchor, 8)
        textView.pinBottom(to: contentView.bottomAnchor, 8)
        textView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, 24)
        textView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, 24)
        textView.setHeight(120)
        textView.delegate = self
    }
}

// MARK: - UITextViewDelegate
extension AddQuestionOpenAnswerTableViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        onTextChanged?(textView.text)
    }
}
