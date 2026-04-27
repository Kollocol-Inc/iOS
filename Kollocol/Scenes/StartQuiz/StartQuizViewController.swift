//
//  StartQuizViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 22.03.2026.
//

import UIKit

final class StartQuizViewController: UIViewController {
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

    private let startQuizButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let title = "quizStartTitle".localized
        static let startButtonReadyTitle = "start".localized
        static let startButtonMissingNameTitle = "specifyTitle".localized
        static let startButtonInvalidDeadlineTitle = "specifyValidDeadline".localized
    }

    // MARK: - Properties
    private var interactor: StartQuizInteractor
    private let initialData: StartQuizModels.InitialData

    private var rows: [StartQuizModels.Row] = []
    private var titleText: String
    private var selectedDeadline = Date()
    private var isStartQuizLoading = false

    private var startButtonBottomConstraint: NSLayoutConstraint?

    private var shouldShowDeadlineParameter: Bool {
        initialData.quizType == .async
    }

    // MARK: - Lifecycle
    init(
        interactor: StartQuizInteractor,
        initialData: StartQuizModels.InitialData
    ) {
        self.interactor = interactor
        self.initialData = initialData
        self.titleText = initialData.title
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
        updateStartButtonState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableInsetsForBottomIsland()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateBottomIslandButtonInset()
        updateTableInsetsForBottomIsland()
    }

    // MARK: - Methods
    @MainActor
    func displayStartQuizLoading(_ isLoading: Bool) {
        isStartQuizLoading = isLoading
        updateStartButtonState()
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
        bottomIslandView.pinBottom(to: view.bottomAnchor)

        bottomIslandView.addSubview(startQuizButton)
        startQuizButton.pinTop(to: bottomIslandView.topAnchor, 12)
        startQuizButton.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        startQuizButton.pinRight(to: bottomIslandView.trailingAnchor, 12)
        startButtonBottomConstraint = startQuizButton.pinBottom(to: bottomIslandView.bottomAnchor)
        updateBottomIslandButtonInset()
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: TextInputTableViewCell.reuseIdentifier)
        tableView.register(StartQuizDeadlineTableViewCell.self, forCellReuseIdentifier: StartQuizDeadlineTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureActions() {
        startQuizButton.addTarget(self, action: #selector(handleStartQuizTap), for: .touchUpInside)
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
            guard let self else { return }
            Task {
                await self.interactor.handleBackTap()
            }
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward", withConfiguration: backConfiguration)?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: backAction
        )
    }

    private func rebuildRows() {
        var newRows: [StartQuizModels.Row] = [
            .header("title".localized),
            .nameInput
        ]

        if shouldShowDeadlineParameter {
            newRows.append(.header("parameters".localized))
            newRows.append(.deadline)
        }

        rows = newRows
    }

    private func updateBottomIslandButtonInset() {
        startButtonBottomConstraint?.constant = -view.safeAreaInsets.bottom
    }

    private func updateTableInsetsForBottomIsland() {
        let bottomInset = bottomIslandView.bounds.height + 8
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func updateStartButtonState() {
        let normalizedTitle = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedTitle.isEmpty == false else {
            applyStartButtonState(
                title: UIConstants.startButtonMissingNameTitle,
                isEnabled: false
            )
            return
        }

        if shouldShowDeadlineParameter {
            let now = Date()
            if selectedDeadline < now {
                if now.timeIntervalSince(selectedDeadline) <= 1 {
                    selectedDeadline = now
                } else {
                    applyStartButtonState(
                        title: UIConstants.startButtonInvalidDeadlineTitle,
                        isEnabled: false
                    )
                    return
                }
            }
        }

        applyStartButtonState(
            title: UIConstants.startButtonReadyTitle,
            isEnabled: true
        )
    }

    private func applyStartButtonState(title: String, isEnabled: Bool) {
        startQuizButton.setTitle(title, for: .normal)
        let isButtonEnabled = isEnabled && isStartQuizLoading == false
        startQuizButton.isEnabled = isButtonEnabled
        startQuizButton.alpha = isButtonEnabled ? 1 : 0.6
    }

    // MARK: - Actions
    @objc
    private func handleStartQuizTap() {
        view.endEditing(true)

        let formData = StartQuizModels.FormData(
            title: titleText,
            deadline: shouldShowDeadlineParameter ? selectedDeadline : nil
        )

        Task {
            await interactor.startQuiz(formData: formData)
        }
    }
}

// MARK: - UITableViewDataSource
extension StartQuizViewController: UITableViewDataSource {
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
                placeholder: "enterTitlePlaceholder".localized,
                isLoading: false
            )
            cell.onTextChanged = { [weak self] newText in
                self?.titleText = newText
                self?.updateStartButtonState()
            }
            return cell

        case .deadline:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: StartQuizDeadlineTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? StartQuizDeadlineTableViewCell else {
                return UITableViewCell()
            }

            let minimumDate = Date()
            if selectedDeadline < minimumDate {
                selectedDeadline = minimumDate
            }

            cell.configure(
                selectedDate: selectedDeadline,
                minimumDate: minimumDate
            )
            cell.onDateChanged = { [weak self] selectedDate in
                self?.selectedDeadline = selectedDate
                self?.updateStartButtonState()
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension StartQuizViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .header:
            return 46
        case .nameInput:
            return UITableView.automaticDimension
        case .deadline:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .nameInput:
            return 70
        case .deadline:
            return 66
        default:
            return 46
        }
    }
}
