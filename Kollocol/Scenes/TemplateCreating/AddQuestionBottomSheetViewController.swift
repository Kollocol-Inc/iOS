//
//  AddQuestionBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class AddQuestionBottomSheetViewController: UIViewController {
    // MARK: - Typealias
    private enum QuestionMode: Int {
        case single
        case multi
        case openEnded

        var title: String {
            switch self {
            case .single:
                return "Single"
            case .multi:
                return "Multi"
            case .openEnded:
                return "Open ended"
            }
        }

        var questionType: QuestionType {
            switch self {
            case .single:
                return .singleChoise
            case .multi:
                return .multiChoice
            case .openEnded:
                return .openEnded
            }
        }
    }

    private struct OptionItem {
        var text: String
        var isCorrect: Bool
    }

    private enum Row {
        case typePicker
        case header(String)
        case questionInput
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
        static let title = "Добавить вопрос"
        static let maxOptionsCount = 10
        static let minOptionsCount = 2
    }

    // MARK: - Properties
    var onSaveQuestion: ((Question) -> Void)?

    private var rows: [Row] = []
    private var mode: QuestionMode = .single
    private var questionText: String = ""
    private var openAnswerText: String = ""
    private var score: Int = 1
    private var timeLimitSec: Int = 30
    private var options: [OptionItem] = []

    private var saveButtonItem: UIBarButtonItem?
    private weak var activeTimePopoverController: AddQuestionTimePopoverViewController?
    private var lastMeasuredSheetHeight: CGFloat = 0

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        rebuildRows()
        configureUI()
        configureNavigationBar()
        updateSaveButtonState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreferredContentSizeIfNeeded()
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
            self?.dismiss(animated: true)
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
            .header("Вопрос"),
            .questionInput,
            .header("Параметры"),
            .parameters,
            .divider
        ]

        switch mode {
        case .openEnded:
            newRows.append(.header("Ответ (опционально)"))
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
        let isQuestionFilled = questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let isValidForMode: Bool

        switch mode {
        case .openEnded:
            isValidForMode = true

        case .single, .multi:
            let filledOptions = options.filter {
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
            let hasEmptyOption = options.contains {
                $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let selectedCount = options.filter(\.isCorrect).count
            isValidForMode = filledOptions.count >= UIConstants.minOptionsCount
                && hasEmptyOption == false
                && selectedCount > 0
        }

        let isEnabled = isQuestionFilled && isValidForMode && timeLimitSec > 0
        saveButtonItem?.isEnabled = isEnabled
        saveButtonItem?.customView?.alpha = isEnabled ? 1 : 0.5
        navigationItem.rightBarButtonItem?.tintColor = isEnabled
            ? .backgroundGreen
            : .backgroundGreen.withAlphaComponent(0.5)
    }

    private func handleModeChanged(_ newMode: QuestionMode) {
        guard mode != newMode else { return }

        let oldRows = rows
        let oldMode = mode
        mode = newMode

        if newMode == .single, oldMode == .multi {
            options = options.map { .init(text: $0.text, isCorrect: false) }
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

        let previousStates = options.map(\.isCorrect)

        switch mode {
        case .single:
            if isOn {
                for itemIndex in options.indices {
                    options[itemIndex].isCorrect = itemIndex == index
                }
            } else {
                options[index].isCorrect = false
            }

        case .multi:
            options[index].isCorrect = isOn

        case .openEnded:
            break
        }

        let changedIndexes = options.indices.filter { previousStates[$0] != options[$0].isCorrect }
        if mode == .single {
            let rowsToReload = changedIndexes
                .filter { $0 != index }
                .map { indexPathForOption($0) }
            if rowsToReload.isEmpty == false {
                tableView.reloadRows(at: rowsToReload, with: .none)
            }
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
                aiAnswer: nil,
                correctAnswer: correctAnswer,
                id: UUID().uuidString,
                maxScore: score,
                options: nil,
                orderIndex: nil,
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
                aiAnswer: nil,
                correctAnswer: correctAnswer,
                id: UUID().uuidString,
                maxScore: score,
                options: normalizedOptions,
                orderIndex: nil,
                text: normalizedQuestion,
                timeLimitSec: timeLimitSec,
                type: .singleChoise
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
                aiAnswer: nil,
                correctAnswer: .multipleChoice(selectedIndexes),
                id: UUID().uuidString,
                maxScore: score,
                options: normalizedOptions,
                orderIndex: nil,
                text: normalizedQuestion,
                timeLimitSec: timeLimitSec,
                type: .multiChoice
            )
        }
    }

    private func handleSaveTap() {
        guard saveButtonItem?.isEnabled == true else { return }
        onSaveQuestion?(buildQuestion())
        dismiss(animated: true)
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
                placeholder: "Введите вопрос",
                isLoading: false
            )
            cell.onTextChanged = { [weak self] text in
                self?.questionText = text
                self?.updateSaveButtonState()
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
                title: "Ответы",
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
        6
    }
}

private final class AddQuestionTypePickerTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Single", "Multi", "Open ended"])
        control.selectedSegmentIndex = 0
        control.backgroundColor = .backgroundSecondary
        control.layer.cornerRadius = 12
        control.clipsToBounds = true
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ],
            for: .normal
        )
        control.setTitleTextAttributes(
            [
                .foregroundColor: UIColor.accentPrimary,
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

private final class AddQuestionParametersTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let scoreTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Балл"
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
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
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
        label.text = "Время"
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
        return String(format: "%02d м. %02d с.", minutes, seconds)
    }

    // MARK: - Actions
    @objc
    private func handleMinusTap() {
        guard score > 1 else { return }
        score -= 1
        scoreLabel.text = "\(score)"
        onScoreChanged?(score)
    }

    @objc
    private func handlePlusTap() {
        score += 1
        scoreLabel.text = "\(score)"
        onScoreChanged?(score)
    }

    @objc
    private func handleTimeTap() {
        onTimeTap?(timeCapsuleButton)
    }

}

private final class AddQuestionTimePopoverViewController: UIViewController {
    // MARK: - UI Components
    private let pickerView = UIPickerView()

    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить", for: .normal)
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
            return timeString(for: row, unit: "м")
        }
        return timeString(for: row, unit: "с")
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
        view.layer.cornerRadius = 17
        view.clipsToBounds = true
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

        addButtonContainerView.addSubview(addButton)
        addButton.pin(to: addButtonContainerView)
        addButton.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)
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
            string: "Введите ответ",
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
                title: "Удалить",
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
