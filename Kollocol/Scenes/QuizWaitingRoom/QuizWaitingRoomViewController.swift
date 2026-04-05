//
//  QuizWaitingRoomViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizWaitingRoomViewController: UIViewController {
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

    private let waitingInfoButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Ожидаем начала...", for: .normal)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.isEnabled = false
        button.alpha = 0.6
        button.setHeight(42)
        return button
    }()

    private let creatorButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.distribution = .fill
        return stack
    }()

    private let startQuizButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Запустить квиз", for: .normal)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    private let cancelQuizButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .backgroundRedSecondary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.setTitle("Отменить квиз", for: .normal)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setHeight(42)
        return button
    }()

    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    private let navigationCodeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .accentPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var navigationTitleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [navigationTitleLabel, navigationCodeLabel])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Constants
    private enum Constants {
        static let defaultNavigationTitle = "Квиз"
    }

    // MARK: - Properties
    private let interactor: QuizWaitingRoomInteractor
    private let initialData: QuizWaitingRoomModels.InitialData

    private var rows: [QuizWaitingRoomModels.Row] = []
    private var participantsCount = 1
    private var isCreator = false
    private var currentUserID: String?
    private var participants: [QuizParticipant] = []

    private var waitingInfoButtonBottomConstraint: NSLayoutConstraint?
    private var creatorButtonsBottomConstraint: NSLayoutConstraint?

    // MARK: - Lifecycle
    init(
        interactor: QuizWaitingRoomInteractor,
        initialData: QuizWaitingRoomModels.InitialData
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
        rebuildRows()
        configureUI()
        configureNavigationBar()
        updateBottomIslandState()

        Task {
            await interactor.handleViewDidLoad()
        }
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
    func displayParticipantsCount(_ count: Int) {
        participantsCount = max(1, count)
        updateStartQuizButtonState()
        rebuildRows()
        tableView.reloadData()
    }

    @MainActor
    func displayQuizTitle(_ quizTitle: String) {
        navigationTitleLabel.text = quizTitle
    }

    @MainActor
    func displayParticipants(_ participants: [QuizParticipant]) {
        self.participants = participants
        participantsCount = max(1, participants.count)
        updateStartQuizButtonState()
        rebuildRows()
        tableView.reloadData()
    }

    @MainActor
    func displayIsCreator(_ isCreator: Bool) {
        self.isCreator = isCreator
        updateStartQuizButtonState()
        updateBottomIslandState()
    }

    @MainActor
    func displayCurrentUserID(_ userID: String?) {
        currentUserID = normalizeUserID(userID)
        tableView.reloadData()
    }

    @MainActor
    func confirmLeaveAfterAlert() {
        Task {
            await interactor.handleLeaveTap()
        }
    }

    @MainActor
    func confirmKickAfterSheet(email: String) {
        Task {
            await interactor.handleKickParticipantConfirmed(email: email)
        }
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

        bottomIslandView.addSubview(waitingInfoButton)
        waitingInfoButton.pinTop(to: bottomIslandView.topAnchor, 12)
        waitingInfoButton.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        waitingInfoButton.pinRight(to: bottomIslandView.trailingAnchor, 12)
        waitingInfoButtonBottomConstraint = waitingInfoButton.pinBottom(to: bottomIslandView.bottomAnchor)

        creatorButtonsStack.addArrangedSubview(startQuizButton)
        creatorButtonsStack.addArrangedSubview(cancelQuizButton)

        bottomIslandView.addSubview(creatorButtonsStack)
        creatorButtonsStack.pinTop(to: bottomIslandView.topAnchor, 12)
        creatorButtonsStack.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        creatorButtonsStack.pinRight(to: bottomIslandView.trailingAnchor, 12)
        creatorButtonsBottomConstraint = creatorButtonsStack.pinBottom(to: bottomIslandView.bottomAnchor)

        updateBottomIslandButtonInset()
    }

    private func configureTableView() {
        tableView.register(
            QuizWaitingRoomParticipantsHeaderTableViewCell.self,
            forCellReuseIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizWaitingRoomParticipantTableViewCell.self,
            forCellReuseIdentifier: QuizWaitingRoomParticipantTableViewCell.reuseIdentifier
        )

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureActions() {
        startQuizButton.addTarget(self, action: #selector(handleStartQuizTap), for: .touchUpInside)
    }

    private func configureNavigationBar() {
        navigationTitleLabel.text = Constants.defaultNavigationTitle
        navigationCodeLabel.text = initialData.accessCode
        navigationItem.titleView = navigationTitleStackView
        navigationItem.hidesBackButton = true

        let leftAction = UIAction { [weak self] _ in
            self?.handleLeaveTap()
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "door.right.hand.open")?
                .withTintColor(.backgroundRedSecondary, renderingMode: .alwaysOriginal),
            primaryAction: leftAction
        )

        let rightAction = UIAction { [weak self] _ in
            self?.handleCopyCodeTap()
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "document.on.document.fill")?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: rightAction
        )
    }

    private func rebuildRows() {
        let headerCount = max(1, participantsCount)
        var updatedRows: [QuizWaitingRoomModels.Row] = [
            .participantsHeader(count: headerCount)
        ]

        for participant in participants {
            updatedRows.append(.participant(participant))
        }

        rows = updatedRows
    }

    private func updateBottomIslandButtonInset() {
        let bottomInset = -view.safeAreaInsets.bottom
        waitingInfoButtonBottomConstraint?.constant = bottomInset
        creatorButtonsBottomConstraint?.constant = bottomInset
    }

    private func updateTableInsetsForBottomIsland() {
        let bottomInset = bottomIslandView.bounds.height + 8
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func updateBottomIslandState() {
        waitingInfoButton.isHidden = isCreator
        creatorButtonsStack.isHidden = isCreator == false

        waitingInfoButtonBottomConstraint?.isActive = isCreator == false
        creatorButtonsBottomConstraint?.isActive = isCreator

        view.layoutIfNeeded()
        updateTableInsetsForBottomIsland()
    }

    private func updateStartQuizButtonState() {
        let isEnabled = isCreator && participantsCount >= 2
        startQuizButton.isEnabled = isEnabled
        startQuizButton.alpha = isEnabled ? 1 : 0.6
        startQuizButton.setTitle(
            isEnabled ? "Запустить квиз" : "Недостаточно участников",
            for: .normal
        )
    }

    private func isCurrentUserParticipant(_ participant: QuizParticipant) -> Bool {
        guard let currentUserID else {
            return false
        }

        return normalizeUserID(participant.userId) == currentUserID
    }

    private func normalizeUserID(_ userID: String?) -> String? {
        let normalizedUserID = userID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return normalizedUserID.isEmpty ? nil : normalizedUserID
    }

    // MARK: - Actions
    @objc
    private func handleStartQuizTap() {
        Task {
            await interactor.handleStartQuizTap()
        }
    }

    private func handleLeaveTap() {
        Task {
            await interactor.handleLeaveAttempt()
        }
    }

    private func handleCopyCodeTap() {
        UIPasteboard.general.string = initialData.accessCode
    }
}

// MARK: - UITableViewDataSource
extension QuizWaitingRoomViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]

        switch row {
        case .participantsHeader(let count):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizWaitingRoomParticipantsHeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(count: count)
            return cell

        case .participant(let participant):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizWaitingRoomParticipantTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizWaitingRoomParticipantTableViewCell else {
                return UITableViewCell()
            }

            let isCurrentUser = participant.map(isCurrentUserParticipant(_:)) ?? false
            let isOffline = participant?.isOnline == false
            let canKickParticipant = isCreator &&
            isCurrentUser == false &&
            (participant?.isCreator == false)
            cell.configure(
                participant: participant,
                isCurrentUser: isCurrentUser,
                isOffline: isOffline,
                canKickParticipant: canKickParticipant
            ) { [weak self] in
                guard let self,
                      let participant else {
                    return
                }

                Task {
                    await self.interactor.handleKickParticipantTap(participant)
                }
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension QuizWaitingRoomViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .participantsHeader:
            return 46
        case .participant:
            return 54
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = rows[indexPath.row]

        switch row {
        case .participantsHeader:
            return 46
        case .participant:
            return 54
        }
    }
}
