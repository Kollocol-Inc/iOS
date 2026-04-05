//
//  QuizParticipatingViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 28.03.2026.
//

import UIKit

final class QuizParticipatingViewController: UIViewController {
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
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 88
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

    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setTitle("Ответить", for: .normal)
        button.setHeight(42)
        return button
    }()

    private let waitingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundPrimary
        view.isHidden = true
        return view
    }()

    private let waitingTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.numberOfLines = 2
        label.text = "Ждем пока\nостальные ответят..."
        return label
    }()

    private let waitingVerticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()

    private let waitingHorizontalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        return stackView
    }()

    private let waitingPlaceholderPillView = QuizParticipatingInfoPillView()
    private let waitingTimerPillView = QuizParticipatingInfoPillView()

    private let asyncCompletionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true

        let text = "Квиз успешно пройден\nОжидайте получения оценки"
        let attributedText = NSMutableAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.textPrimary
            ]
        )

        if let lineBreakRange = text.range(of: "\n") {
            let secondLineStartIndex = text.distance(from: text.startIndex, to: lineBreakRange.upperBound)
            let secondLineLength = text.count - secondLineStartIndex
            attributedText.addAttributes(
                [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.textSecondary
                ],
                range: NSRange(location: secondLineStartIndex, length: secondLineLength)
            )
        }

        label.attributedText = attributedText
        return label
    }()

    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Properties
    private let interactor: QuizParticipatingInteractor

    private var rows: [QuizParticipatingModels.Row] = []
    private var state = QuizParticipatingModels.ViewState(
        questionPayload: nil,
        openAnswerText: "",
        selectedOptionIndexes: [],
        phase: .participantAnswering,
        isCreator: false,
        isAsyncQuiz: false,
        participantRows: [],
        optionAnswerCounts: [:],
        waitingAnsweredCount: 0,
        waitingTotalParticipantsCount: 0,
        bottomButtonTitle: "Ответить",
        isBottomButtonEnabled: false,
        isTimerVisible: true,
        topLeaders: [],
        personalResult: nil,
        finalParticipants: []
    )

    private var bottomButtonBottomConstraint: NSLayoutConstraint?
    private var timerTask: Task<Void, Never>?
    private var timerDeadlineDate: Date?
    private var remainingSeconds = 0
    private var currentQuestionIdentity: String?
    private var serverClockOffsetMs: Int64?
    private var questionServerDeadlineMs: Int64?

    // MARK: - Lifecycle
    init(interactor: QuizParticipatingInteractor) {
        self.interactor = interactor
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

    deinit {
        timerTask?.cancel()
    }

    // MARK: - Methods
    @MainActor
    func displayQuizTitle(_ quizTitle: String) {
        navigationTitleLabel.text = quizTitle
        navigationItem.titleView = navigationTitleLabel
    }

    @MainActor
    func displayState(_ state: QuizParticipatingModels.ViewState) {
        let newQuestionIdentity = questionIdentity(for: state.questionPayload)
        let didReceiveNewQuestion = newQuestionIdentity != currentQuestionIdentity
        let previousQuestionPayload = self.state.questionPayload
        let shouldReconfigureTimer = shouldReconfigureTimer(
            from: previousQuestionPayload,
            to: state.questionPayload,
            didReceiveNewQuestion: didReceiveNewQuestion
        )

        self.state = state
        currentQuestionIdentity = newQuestionIdentity

        if state.isTimerVisible == false {
            stopTimer()
        } else if shouldReconfigureTimer {
            configureTimer(for: state.questionPayload)
        } else if state.questionPayload == nil {
            stopTimer()
        }

        updateBottomButtonState()

        let shouldShowWaitingOverlay = state.phase == .participantSubmittedWaitingOthers
            && state.isAsyncQuiz == false
        waitingOverlayView.isHidden = shouldShowWaitingOverlay == false
        updateWaitingOverlayParticipantsPill()
        updateWaitingOverlayTimerPill()

        rebuildRows()
        tableView.reloadData()
        updateAsyncCompletionLabelVisibility()
    }

    @MainActor
    func confirmLeaveAfterAlert() {
        Task {
            await interactor.handleLeaveTap()
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

        bottomIslandView.addSubview(submitButton)
        submitButton.pinTop(to: bottomIslandView.topAnchor, 12)
        submitButton.pinLeft(to: bottomIslandView.leadingAnchor, 12)
        submitButton.pinRight(to: bottomIslandView.trailingAnchor, 12)
        bottomButtonBottomConstraint = submitButton.pinBottom(to: bottomIslandView.bottomAnchor)
        updateBottomIslandButtonInset()

        view.addSubview(waitingOverlayView)
        waitingOverlayView.pin(to: view)

        waitingOverlayView.addSubview(waitingVerticalStackView)
        waitingVerticalStackView.pinCenter(to: waitingOverlayView)

        waitingVerticalStackView.addArrangedSubview(waitingTitleLabel)
        waitingVerticalStackView.addArrangedSubview(waitingHorizontalStackView)

        waitingHorizontalStackView.addArrangedSubview(waitingPlaceholderPillView)
        waitingPlaceholderPillView.setWidth(86)
        waitingPlaceholderPillView.setHeight(42)
        waitingPlaceholderPillView.configureEmpty()

        waitingHorizontalStackView.addArrangedSubview(waitingTimerPillView)
        waitingTimerPillView.setWidth(86)
        waitingTimerPillView.setHeight(42)

        tableView.addSubview(asyncCompletionLabel)
        asyncCompletionLabel.pinCenter(to: tableView)
        asyncCompletionLabel.pinHorizontal(to: tableView, 24, mode: .grOE)
    }

    private func configureTableView() {
        tableView.register(
            QuizParticipatingQuestionInfoTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingQuestionInfoTableViewCell.reuseIdentifier
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
            QuizParticipatingOptionTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingOptionTableViewCell.reuseIdentifier
        )
        tableView.register(
            DividerTableViewCell.self,
            forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizWaitingRoomParticipantsHeaderTableViewCell.self,
            forCellReuseIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizWaitingRoomParticipantTableViewCell.self,
            forCellReuseIdentifier: QuizWaitingRoomParticipantTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingParticipantTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingParticipantTableViewCell.reuseIdentifier
        )
        tableView.register(
            HeaderTableViewCell.self,
            forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingTopLeadersTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingTopLeadersTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingPersonalResultTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingPersonalResultTableViewCell.reuseIdentifier
        )
        tableView.register(
            QuizParticipatingFinalParticipantTableViewCell.self,
            forCellReuseIdentifier: QuizParticipatingFinalParticipantTableViewCell.reuseIdentifier
        )

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureActions() {
        submitButton.addTarget(self, action: #selector(handleSubmitTap), for: .touchUpInside)
    }

    private func configureNavigationBar() {
        let leftAction = UIAction { [weak self] _ in
            self?.handleLeaveTap()
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "door.right.hand.open")?
                .withTintColor(.backgroundRedSecondary, renderingMode: .alwaysOriginal),
            primaryAction: leftAction
        )

        navigationItem.hidesBackButton = true
    }

    private func applyBottomButtonState(title: String, isEnabled: Bool) {
        submitButton.setTitle(title, for: .normal)
        submitButton.isEnabled = isEnabled
        submitButton.alpha = isEnabled ? 1 : 0.6
    }

    private func updateBottomButtonState() {
        let isEnabled = state.isBottomButtonEnabled && shouldAllowAnswerSubmit()
        applyBottomButtonState(
            title: state.bottomButtonTitle,
            isEnabled: isEnabled
        )
    }

    private func shouldAllowAnswerSubmit() -> Bool {
        if state.isCreator {
            return true
        }

        if state.phase != .participantAnswering {
            return true
        }

        guard state.questionPayload != nil else {
            return true
        }

        return remainingSeconds > 0
    }

    private func rebuildRows() {
        var updatedRows: [QuizParticipatingModels.Row] = []

        if state.phase == .quizFinished {
            if state.isAsyncQuiz && state.isCreator == false {
                rows = []
                return
            }

            updatedRows.append(.header(title: "Таблица лидеров"))
            updatedRows.append(.topLeaders(state.topLeaders))

            let participantsCount = state.topLeaders.count + state.finalParticipants.count

            if state.isCreator == false,
               let personalResult = state.personalResult {
                updatedRows.append(.divider)
                updatedRows.append(.personalResult(personalResult))
            }

            if participantsCount > 3 {
                updatedRows.append(.divider)
                updatedRows.append(
                    .participantsHeader(
                        title: "Остальные участники",
                        count: state.finalParticipants.count
                    )
                )
                state.finalParticipants.forEach { participant in
                    updatedRows.append(.finalParticipant(participant))
                }
            }

            rows = updatedRows
            return
        }

        if let questionPayload = state.questionPayload {
            updatedRows.append(
                .questionInfo(
                    .init(
                        questionNumber: questionPayload.questionIndex + 1,
                        totalQuestions: questionPayload.totalQuestions,
                        maxScore: questionPayload.question.maxScore ?? 0,
                        remainingSeconds: remainingSeconds,
                        isTimerVisible: state.isTimerVisible
                    )
                )
            )
            updatedRows.append(.questionText(questionPayload.question.text ?? ""))

            if questionPayload.question.type == .openEnded,
               state.isCreator == false,
               state.phase == .participantAnswering || state.phase == .participantSubmittedWaitingOthers {
                let isAnswerSubmissionPending = state.phase == .participantSubmittedWaitingOthers
                updatedRows.append(
                    .openAnswerInput(
                        text: state.openAnswerText,
                        isEditable: state.phase == .participantAnswering && isAnswerSubmissionPending == false,
                        isLoading: isAnswerSubmissionPending
                    )
                )
            } else if questionPayload.question.type == .singleChoice || questionPayload.question.type == .multiChoice {
                let kind: AnswerOptionMarkControl.Kind = questionPayload.question.type == .multiChoice
                ? .multipleChoice
                : .singleChoice
                let isAnswersCountVisible = state.isCreator || state.phase == .participantWaitingForCreator
                let isAnswerSubmissionPending = state.phase == .participantSubmittedWaitingOthers

                for (index, optionText) in questionPayload.question.options.enumerated() {
                    let optionViewData = QuizParticipatingModels.OptionViewData(
                        index: index,
                        text: optionText,
                        kind: kind,
                        isSelected: state.selectedOptionIndexes.contains(index),
                        isEnabled: state.isCreator == false
                            && state.phase == .participantAnswering
                            && isAnswerSubmissionPending == false,
                        isLoading: isAnswerSubmissionPending,
                        answersCount: state.optionAnswerCounts[index] ?? 0,
                        isAnswersCountVisible: isAnswersCountVisible
                    )
                    updatedRows.append(.answerOption(optionViewData))
                }
            }
        }

        let shouldShowParticipantsSection = state.isCreator || state.phase == .participantWaitingForCreator
        if shouldShowParticipantsSection {
            let headerTitle = "Таблица лидеров"

            if updatedRows.isEmpty == false {
                updatedRows.append(.divider)
            }
            updatedRows.append(
                .participantsHeader(
                    title: headerTitle,
                    count: state.participantRows.count
                )
            )
            state.participantRows.forEach { participantRow in
                updatedRows.append(.participant(participantRow))
            }
        }

        rows = updatedRows
    }

    private func updateAsyncCompletionLabelVisibility() {
        asyncCompletionLabel.isHidden = !(state.phase == .quizFinished && state.isAsyncQuiz && state.isCreator == false)
    }

    private func configureTimer(for questionPayload: QuizQuestionPayload?) {
        guard let questionPayload else {
            stopTimer()
            return
        }

        let defaultTimeLimitMs = Int64((questionPayload.question.timeLimitSec ?? 0) * 1000)
        let timeLimitMs = max(0, questionPayload.timeLimitMs ?? defaultTimeLimitMs)

        if timeLimitMs <= 0 {
            remainingSeconds = 0
            stopTimer()
            return
        }

        let localNowMs = currentUnixTimestampMs()
        let remainingMs: Int64
        if let serverTimeMs = questionPayload.serverTime {
            updateServerClockOffset(serverTimeMs: serverTimeMs, localNowMs: localNowMs)

            let effectiveServerOffsetMs = serverClockOffsetMs ?? (serverTimeMs - localNowMs)
            questionServerDeadlineMs = serverTimeMs + timeLimitMs
            let estimatedServerNowMs = localNowMs + effectiveServerOffsetMs
            remainingMs = max(0, (questionServerDeadlineMs ?? 0) - estimatedServerNowMs)
        } else {
            questionServerDeadlineMs = nil
            remainingMs = timeLimitMs
        }

        applyRemainingTime(remainingMs)
        restartTimerTask()
    }

    private func restartTimerTask() {
        timerTask?.cancel()

        timerTask = Task { [weak self] in
            guard let self else { return }

            while Task.isCancelled == false {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled {
                    return
                }

                await MainActor.run {
                    self.tickTimer()
                }
            }
        }
    }

    private func tickTimer() {
        let remainingMs: Int64

        if let questionServerDeadlineMs,
           let serverClockOffsetMs {
            let localNowMs = currentUnixTimestampMs()
            let estimatedServerNowMs = localNowMs + serverClockOffsetMs
            remainingMs = max(0, questionServerDeadlineMs - estimatedServerNowMs)
        } else if let timerDeadlineDate {
            remainingMs = max(0, Int64(ceil(timerDeadlineDate.timeIntervalSinceNow * 1000)))
        } else {
            remainingMs = 0
        }

        guard remainingMs > 0 else {
            timerTask?.cancel()
            timerTask = nil
            remainingSeconds = 0
            updateWaitingOverlayTimerPill()
            return
        }

        remainingSeconds = Int(ceil(Double(remainingMs) / 1000))

        if rows.isEmpty == false {
            rebuildRows()
            let topIndexPath = IndexPath(row: 0, section: 0)
            if tableView.numberOfRows(inSection: 0) > topIndexPath.row {
                tableView.reloadRows(at: [topIndexPath], with: .none)
            }
        }

        updateBottomButtonState()
        updateWaitingOverlayTimerPill()

        if remainingSeconds == 0 {
            timerTask?.cancel()
            timerTask = nil
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        timerDeadlineDate = nil
        questionServerDeadlineMs = nil
        remainingSeconds = 0
        updateWaitingOverlayTimerPill()
    }

    private func updateWaitingOverlayTimerPill() {
        let isCritical = remainingSeconds < 10
        let timerTextColor: UIColor = isCritical ? .backgroundRedSecondary : .textWhite
        waitingTimerPillView.configure(
            iconName: "clock.fill",
            text: formatTime(remainingSeconds),
            tintColor: timerTextColor
        )
    }

    private func updateWaitingOverlayParticipantsPill() {
        let answered = max(0, state.waitingAnsweredCount)
        let total = max(answered, state.waitingTotalParticipantsCount)
        waitingPlaceholderPillView.configure(
            iconName: "person.2.fill",
            text: "\(answered)/\(total)",
            tintColor: .textWhite
        )
    }

    private func applyRemainingTime(_ remainingMs: Int64) {
        let normalizedRemainingMs = max(0, remainingMs)
        remainingSeconds = Int(ceil(Double(normalizedRemainingMs) / 1000))
        timerDeadlineDate = Date().addingTimeInterval(TimeInterval(normalizedRemainingMs) / 1000)
    }

    private func updateServerClockOffset(serverTimeMs: Int64, localNowMs: Int64) {
        serverClockOffsetMs = serverTimeMs - localNowMs
    }

    private func currentUnixTimestampMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private func shouldReconfigureTimer(
        from previousPayload: QuizQuestionPayload?,
        to currentPayload: QuizQuestionPayload?,
        didReceiveNewQuestion: Bool
    ) -> Bool {
        if didReceiveNewQuestion {
            return true
        }

        guard let previousPayload,
              let currentPayload else {
            return previousPayload == nil && currentPayload != nil
        }

        return previousPayload.serverTime != currentPayload.serverTime
            || previousPayload.timeLimitMs != currentPayload.timeLimitMs
    }

    private func formatTime(_ seconds: Int) -> String {
        let normalizedSeconds = max(0, seconds)
        let minutes = normalizedSeconds / 60
        let secondsPart = normalizedSeconds % 60
        return String(format: "%02d:%02d", minutes, secondsPart)
    }

    private func questionIdentity(for payload: QuizQuestionPayload?) -> String? {
        guard let payload else { return nil }
        return "\(payload.question.id ?? "none"):\(payload.questionIndex)"
    }

    private func updateBottomIslandButtonInset() {
        bottomButtonBottomConstraint?.constant = -view.safeAreaInsets.bottom
    }

    private func updateTableInsetsForBottomIsland() {
        let bottomInset = bottomIslandView.bounds.height + 8
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func visibleOpenAnswerText() -> String? {
        guard state.questionPayload?.question.type == .openEnded else {
            return nil
        }

        let openAnswerCell = tableView.visibleCells
            .compactMap { $0 as? QuizParticipatingOpenAnswerTableViewCell }
            .first

        return openAnswerCell?.currentText
    }

    // MARK: - Actions
    @objc
    private func handleSubmitTap() {
        guard shouldAllowAnswerSubmit() else {
            return
        }

        let openAnswerText = visibleOpenAnswerText()
        view.endEditing(true)

        Task {
            if let openAnswerText {
                await interactor.handleOpenAnswerTextChanged(openAnswerText)
            }
            await interactor.handleSubmitTap()
        }
    }

    private func handleLeaveTap() {
        Task {
            await interactor.handleLeaveAttempt()
        }
    }
}

// MARK: - UITableViewDataSource
extension QuizParticipatingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .header(let title):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: HeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title)
            return cell

        case .topLeaders(let leaders):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingTopLeadersTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingTopLeadersTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: leaders)
            return cell

        case .personalResult(let personalResult):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingPersonalResultTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingPersonalResultTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: personalResult)
            return cell

        case .questionInfo(let viewData):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingQuestionInfoTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingQuestionInfoTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: viewData)
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

        case .openAnswerInput(let text, let isEditable, let isLoading):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingOpenAnswerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingOpenAnswerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text, isEditable: isEditable, isLoading: isLoading)
            cell.onDidEndEditing = { [weak self] value in
                guard let self else { return }
                Task {
                    await self.interactor.handleOpenAnswerTextChanged(value)
                }
            }
            return cell

        case .answerOption(let optionViewData):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingOptionTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingOptionTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: optionViewData)
            cell.onTap = { [weak self] in
                guard let self else { return }
                Task {
                    await self.interactor.handleOptionTap(optionViewData.index)
                }
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

        case .participantsHeader(let title, let count):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizWaitingRoomParticipantsHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizWaitingRoomParticipantsHeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title, count: count)
            return cell

        case .participant(let participantRow):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingParticipantTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingParticipantTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: participantRow)
            cell.contentView.alpha = (participantRow.isDimmed || participantRow.isOffline) ? 0.6 : 1
            return cell

        case .finalParticipant(let participantRow):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: QuizParticipatingFinalParticipantTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? QuizParticipatingFinalParticipantTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: participantRow)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension QuizParticipatingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .header:
            return 46
        case .topLeaders:
            return UITableView.automaticDimension
        case .personalResult:
            return 96
        case .questionInfo:
            return 66
        case .divider:
            return 18
        case .participantsHeader:
            return 46
        case .participant,
                .finalParticipant:
            return 54
        case .questionText,
                .openAnswerInput,
                .answerOption:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .header:
            return 46
        case .topLeaders:
            return 160
        case .personalResult:
            return 96
        case .questionInfo:
            return 66
        case .divider:
            return 18
        case .participantsHeader:
            return 46
        case .participant,
                .finalParticipant:
            return 54
        case .questionText:
            return 96
        case .openAnswerInput:
            return 140
        case .answerOption:
            return 64
        }
    }
}
