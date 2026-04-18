//
//  QuizParticipantsOverviewViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

final class QuizParticipantsOverviewViewController: UIViewController {
    // MARK: - UI Components
    private let searchTextField: UITextField = {
        let field = UITextField()
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
        field.attributedPlaceholder = NSAttributedString(
            string: "Поиск участников",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )

        let iconConfiguration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 15, weight: .medium))
        let iconImage = UIImage(systemName: "magnifyingglass", withConfiguration: iconConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.frame = CGRect(x: 12, y: 14.5, width: 15, height: 15)

        let leftAccessoryView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 44))
        leftAccessoryView.addSubview(iconImageView)
        field.leftView = leftAccessoryView
        field.leftViewMode = .always

        field.addPadding(right: 12)
        field.setHeight(44)
        return field
    }()

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
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        return control
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

    private let cancelQuizButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .backgroundRedSecondary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setTitle("Отменить квиз", for: .normal)
        button.setHeight(42)
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let topInset: CGFloat = 12
        static let horizontalInset: CGFloat = 12
        static let searchToTableSpacing: CGFloat = 16
        static let singleEmptyStateTopInset: CGFloat = 8

        static let emptyParticipantsMessage = "Нет участников"
        static let emptyFinishedParticipantsMessage = "Нет участников, прошедших квиз"
        static let emptyNotStartedParticipantsMessage = "Нет участников, которые не приступили к прохождению"
        static let emptySearchParticipantsMessage = "Нет участников с таким именем, фамилией или почтой"

        static let passedTitle = "Прошли"
        static let notStartedTitle = "Не приступили"

        static let publishUnavailableTitle = "С прискорбием сообщаем..."
        static let publishUnavailableAsyncDescription = "Опубликовать результаты можно после конца дедлайна"
        static let publishUnavailableReviewDescription = "Для публикации результатов необходимо оценить всех участников"

        static let publishConfirmTitle = "Внимание"
        static let publishConfirmDescription = "Вы уверены, что хотите опубликовать результаты? Все участники получат уведомление. Это действие необратимо"
        static let publishConfirmActionTitle = "Опубликовать"
        static let cancelActionTitle = "Отмена"
    }

    // MARK: - Properties
    private let interactor: QuizParticipantsOverviewInteractor
    private let initialData: QuizParticipantsOverviewModels.InitialData

    private var rows: [QuizParticipantsOverviewModels.Row] = []
    private var participants: [QuizInstanceParticipant] = []
    private var searchText = ""
    private var currentQuizStatus: QuizStatus?

    private var startButtonBottomConstraint: NSLayoutConstraint?
    private var previousNavigationBarTintColor: UIColor?
    private var previousBackIndicatorImage: UIImage?
    private var previousBackIndicatorTransitionMaskImage: UIImage?

    private var shouldShowBottomIsland: Bool {
        initialData.mode == .asyncState
    }

    private var shouldApplySingleEmptyStateTopInset: Bool {
        guard rows.count == 1 else {
            return false
        }

        if case .empty = rows[0] {
            return true
        }

        return false
    }

    private var isPublishButtonHidden: Bool {
        currentQuizStatus == .publishedResults
    }

    private var hasPendingReviewParticipants: Bool {
        participants.isEmpty || participants.contains { $0.reviewStatus != .reviewed }
    }

    // MARK: - Lifecycle
    init(
        interactor: QuizParticipantsOverviewInteractor,
        initialData: QuizParticipantsOverviewModels.InitialData
    ) {
        self.interactor = interactor
        self.initialData = initialData
        self.currentQuizStatus = initialData.quizStatus
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

        Task {
            await interactor.fetchParticipants()
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
    func displayParticipants(_ participants: [QuizInstanceParticipant]) {
        self.participants = participants
        rebuildRows()
        tableView.reloadData()
        updateTableInsetsForBottomIsland()
        refreshControl.endRefreshing()
        updatePublishBarButtonItem()
    }

    @MainActor
    func displayQuizResultsPublished() {
        currentQuizStatus = .publishedResults
        updatePublishBarButtonItem()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
        configureActions()
    }

    private func configureConstraints() {
        view.addSubview(searchTextField)
        searchTextField.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.topInset)
        searchTextField.pinLeft(to: view.leadingAnchor, UIConstants.horizontalInset)
        searchTextField.pinRight(to: view.trailingAnchor, UIConstants.horizontalInset)

        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinTop(to: searchTextField.bottomAnchor, UIConstants.searchToTableSpacing)
        tableBackgroundView.pinLeft(to: view.leadingAnchor)
        tableBackgroundView.pinRight(to: view.trailingAnchor)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)

        guard shouldShowBottomIsland else { return }

        view.addSubview(bottomIslandView)
        bottomIslandView.pinLeft(to: view.leadingAnchor)
        bottomIslandView.pinRight(to: view.trailingAnchor)
        bottomIslandView.pinBottom(to: view.bottomAnchor)

        bottomIslandView.addSubview(cancelQuizButton)
        cancelQuizButton.pinTop(to: bottomIslandView.topAnchor, 12)
        cancelQuizButton.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        cancelQuizButton.pinRight(to: bottomIslandView.trailingAnchor, 12)
        startButtonBottomConstraint = cancelQuizButton.pinBottom(to: bottomIslandView.bottomAnchor)
        updateBottomIslandButtonInset()
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(
            QuizWaitingRoomParticipantsHeaderTableViewCell.self,
            forCellReuseIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipantsOverviewReviewHeaderTableViewCell.self,
            forCellReuseIdentifier: QuizParticipantsOverviewReviewHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipantsOverviewParticipantTableViewCell.self,
            forCellReuseIdentifier: QuizParticipantsOverviewParticipantTableViewCell.reuseIdentifier
        )
        tableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
    }

    private func configureActions() {
        searchTextField.addTarget(self, action: #selector(handleSearchTextChanged), for: .editingChanged)
    }

    private func configureNavigationBar() {
        let titleLabel = UILabel()
        let normalizedTitle = initialData.quizTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        titleLabel.text = normalizedTitle.isEmpty ? "Квиз" : normalizedTitle
        titleLabel.textColor = .textSecondary
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        navigationItem.titleView = titleLabel

        updatePublishBarButtonItem()
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

    private func updatePublishBarButtonItem() {
        guard isPublishButtonHidden == false else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        let buttonAlpha = publishButtonAlpha()
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        let image = UIImage(systemName: "paperplane.fill", withConfiguration: imageConfiguration)?
            .withTintColor(.textSecondary.withAlphaComponent(buttonAlpha), renderingMode: .alwaysOriginal)

        let action = UIAction { [weak self] _ in
            self?.handlePublishResultsTap()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, primaryAction: action)
    }

    private func publishButtonAlpha() -> CGFloat {
        switch initialData.mode {
        case .asyncState:
            return 0.6

        case .review:
            return hasPendingReviewParticipants ? 0.6 : 1
        }
    }

    private func updateBottomIslandButtonInset() {
        startButtonBottomConstraint?.constant = -view.safeAreaInsets.bottom
    }

    private func updateTableInsetsForBottomIsland() {
        let topInset = shouldApplySingleEmptyStateTopInset ? UIConstants.singleEmptyStateTopInset : 0

        guard shouldShowBottomIsland else {
            tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            tableView.verticalScrollIndicatorInsets = .zero
            return
        }

        let bottomInset = bottomIslandView.bounds.height + 8
        tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: bottomInset, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
    }

    private func rebuildRows() {
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let isSearchActive = trimmedSearchText.isEmpty == false

        switch initialData.mode {
        case .asyncState:
            rows = buildAsyncRows(isSearchActive: isSearchActive)

        case .review:
            rows = buildReviewRows()
        }
    }

    private func buildAsyncRows(isSearchActive: Bool) -> [QuizParticipantsOverviewModels.Row] {
        guard participants.isEmpty == false else {
            return [.empty(text: UIConstants.emptyParticipantsMessage)]
        }

        let filteredParticipants = self.filteredParticipants()
        let finishedParticipants = filteredParticipants.filter { participant in
            participant.sessionStatus == .finished
        }
        let notStartedParticipants = filteredParticipants.filter { participant in
            participant.sessionStatus == .joined || participant.sessionStatus == .inProgress
        }

        var result: [QuizParticipantsOverviewModels.Row] = []
        appendFinishedSectionRows(
            participants: finishedParticipants,
            emptyText: isSearchActive
                ? UIConstants.emptySearchParticipantsMessage
                : UIConstants.emptyFinishedParticipantsMessage,
            into: &result
        )
        appendAsyncSectionRows(
            title: UIConstants.notStartedTitle,
            participants: notStartedParticipants,
            emptyText: isSearchActive
            ? UIConstants.emptySearchParticipantsMessage
            : UIConstants.emptyNotStartedParticipantsMessage,
            showsChevron: false,
            isDimmed: true,
            appendStatusIcon: false,
            into: &result
        )

        return result
    }

    private func buildReviewRows() -> [QuizParticipantsOverviewModels.Row] {
        guard participants.isEmpty == false else {
            return [.empty(text: UIConstants.emptyParticipantsMessage)]
        }

        let filteredParticipants = self.filteredParticipants()
        let reviewedCount = filteredParticipants.filter { $0.reviewStatus == .reviewed }.count

        var result: [QuizParticipantsOverviewModels.Row] = [
            .reviewHeader(
                title: "Участники",
                totalCount: filteredParticipants.count,
                reviewedCount: reviewedCount
            )
        ]

        if filteredParticipants.isEmpty {
            result.append(.empty(text: UIConstants.emptyParticipantsMessage))
            return result
        }

        filteredParticipants.forEach { participant in
            result.append(
                .participant(
                    makeParticipantRowData(
                        from: participant,
                        showsChevron: true,
                        isDimmed: false,
                        appendStatusIcon: true
                    )
                )
            )
        }

        return result
    }

    private func appendFinishedSectionRows(
        participants: [QuizInstanceParticipant],
        emptyText: String,
        into rows: inout [QuizParticipantsOverviewModels.Row]
    ) {
        if participants.isEmpty {
            rows.append(.header(title: UIConstants.passedTitle))
            rows.append(.empty(text: emptyText))
            return
        }

        let reviewedCount = participants.filter { $0.reviewStatus == .reviewed }.count
        rows.append(
            .reviewHeader(
                title: UIConstants.passedTitle,
                totalCount: participants.count,
                reviewedCount: reviewedCount
            )
        )
        participants.forEach { participant in
            rows.append(
                .participant(
                    makeParticipantRowData(
                        from: participant,
                        showsChevron: true,
                        isDimmed: false,
                        appendStatusIcon: true
                    )
                )
            )
        }
    }

    private func appendAsyncSectionRows(
        title: String,
        participants: [QuizInstanceParticipant],
        emptyText: String,
        showsChevron: Bool,
        isDimmed: Bool,
        appendStatusIcon: Bool,
        into rows: inout [QuizParticipantsOverviewModels.Row]
    ) {
        if participants.isEmpty {
            rows.append(.header(title: title))
            rows.append(.empty(text: emptyText))
            return
        }

        rows.append(.headerWithCount(title: title, count: participants.count))
        participants.forEach { participant in
            rows.append(
                .participant(
                    makeParticipantRowData(
                        from: participant,
                        showsChevron: showsChevron,
                        isDimmed: isDimmed,
                        appendStatusIcon: appendStatusIcon
                    )
                )
            )
        }
    }

    private func filteredParticipants() -> [QuizInstanceParticipant] {
        let normalizedSearchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard normalizedSearchText.isEmpty == false else {
            return participants
        }

        return participants.filter { participant in
            let fullName = makeParticipantFullName(participant).lowercased()
            let email = participant.email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
            let searchableText = [fullName, email]
                .filter { $0.isEmpty == false }
                .joined(separator: " ")

            return searchableText.localizedCaseInsensitiveContains(normalizedSearchText)
        }
    }

    private func makeParticipantRowData(
        from participant: QuizInstanceParticipant,
        showsChevron: Bool,
        isDimmed: Bool,
        appendStatusIcon: Bool
    ) -> QuizParticipantsOverviewModels.ParticipantRowData {
        let leftStatusIcon: QuizParticipantsOverviewModels.LeftStatusIcon? = {
            guard appendStatusIcon else { return nil }

            if participant.reviewStatus == .reviewed {
                return .reviewed
            }

            return .pendingReview
        }()

        return QuizParticipantsOverviewModels.ParticipantRowData(
            userId: participant.userId,
            fullName: makeParticipantFullName(participant),
            email: participant.email,
            avatarURL: participant.avatarURL,
            leftStatusIcon: leftStatusIcon,
            showsChevron: showsChevron,
            isDimmed: isDimmed
        )
    }

    private func makeParticipantFullName(_ participant: QuizInstanceParticipant) -> String {
        let fullName = [participant.firstName, participant.lastName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        return fullName.isEmpty ? "Участник" : fullName
    }

    private func handlePublishResultsTap() {
        switch initialData.mode {
        case .asyncState:
            showInfoBottomSheet(
                title: UIConstants.publishUnavailableTitle,
                description: UIConstants.publishUnavailableAsyncDescription,
                buttonTitle: "ОК"
            )

        case .review:
            guard hasPendingReviewParticipants == false else {
                showInfoBottomSheet(
                    title: UIConstants.publishUnavailableTitle,
                    description: UIConstants.publishUnavailableReviewDescription,
                    buttonTitle: "ОК"
                )
                return
            }

            let content = InfoBottomSheetContent(
                title: UIConstants.publishConfirmTitle,
                description: UIConstants.publishConfirmDescription,
                buttonsConfiguration: .double(
                    left: InfoBottomSheetAction(
                        identifier: .cancel,
                        title: UIConstants.cancelActionTitle,
                        style: .buttonSecondary
                    ),
                    right: InfoBottomSheetAction(
                        identifier: .confirm,
                        title: UIConstants.publishConfirmActionTitle,
                        style: .accentPrimary
                    )
                )
            )

            showInfoBottomSheet(content) { [weak self] action in
                guard action == .confirm else { return }

                Task { [weak self] in
                    await self?.interactor.publishQuizResults()
                }
            }
        }
    }

    // MARK: - Actions
    @objc
    private func handleSearchTextChanged() {
        searchText = searchTextField.text ?? ""
        rebuildRows()
        tableView.reloadData()
        updateTableInsetsForBottomIsland()
    }

    @objc
    private func handlePullToRefresh() {
        Task {
            await interactor.fetchParticipants()
        }
    }
}

// MARK: - UITableViewDataSource
extension QuizParticipantsOverviewViewController: UITableViewDataSource {
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

        case .headerWithCount(let title, let count):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizWaitingRoomParticipantsHeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title, count: count)
            return cell

        case .reviewHeader(let title, let totalCount, let reviewedCount):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipantsOverviewReviewHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipantsOverviewReviewHeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: title,
                totalCount: totalCount,
                reviewedCount: reviewedCount
            )
            return cell

        case .participant(let data):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipantsOverviewParticipantTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipantsOverviewParticipantTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: data)
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
extension QuizParticipantsOverviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .header:
            return 46
        case .headerWithCount:
            return UITableView.automaticDimension
        case .reviewHeader:
            return UITableView.automaticDimension
        case .participant:
            return UITableView.automaticDimension
        case .empty:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .empty:
            return 34
        case .participant:
            return 54
        default:
            return 44
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - InfoBottomSheetPresenting
extension QuizParticipantsOverviewViewController: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        self
    }
}
