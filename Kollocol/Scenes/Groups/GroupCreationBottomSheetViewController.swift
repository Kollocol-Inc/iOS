//
//  GroupCreationBottomSheetViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import UIKit
import Mantis

final class GroupCreationBottomSheetViewController: UIViewController {
    // MARK: - Typealias
    typealias AvatarPayload = AvatarPickerController.AvatarPayload

    struct EditInitialData {
        let avatarUrl: String?
        let name: String
        let description: String?
    }

    struct EditGroupRequest {
        let name: String
        let description: String?
        let avatarAction: AvatarAction

        enum AvatarAction {
            case unchanged
            case update(data: Data)
            case remove
        }
    }

    enum Mode {
        case create
        case edit(initialData: EditInitialData)
        case inviteMembers
    }

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
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.keyboardDismissMode = .onDrag
        tableView.layer.cornerRadius = 28
        tableView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        tableView.clipsToBounds = true
        return tableView
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

    private let createButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setHeight(42)
        return button
    }()

    private lazy var createButtonLoader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .textWhite
        view.hidesWhenStopped = true
        return view
    }()

    private let avatarPickerView: AvatarPickerView = {
        let view = AvatarPickerView()
        view.setPlaceholderImage(.groupsAvatarPlaceholder)
        return view
    }()

    // MARK: - Constants
    private enum Section {
        case avatar
        case name
        case description
        case divider
        case participants
    }

    private enum UIConstants {
        static let participantsInfoDescription = "groupsParticipantsInfoDescription".localized
        static let tableTopInset: CGFloat = 8
        static let buttonHorizontalInset: CGFloat = 12
        static let buttonVerticalInset: CGFloat = 12
        static let buttonBottomInset: CGFloat = 12
        static let keyboardButtonBottomInset: CGFloat = 8
        static let keyboardCornerCoverInset: CGFloat = 16
        static let tableBottomSpacing: CGFloat = 8

        static let avatarRowHeight: CGFloat = 95
        static let headerRowHeight: CGFloat = 46
        static let participantsHeaderHeight: CGFloat = 38
        static let participantsRowHeight: CGFloat = 44
        static let descriptionToDividerSpacing: CGFloat = 12
    }

    // MARK: - Properties
    var onCreateGroup: (@MainActor (String, String?, [String], Data?) async -> Bool)?
    var onEditGroup: (@MainActor (EditGroupRequest) async -> Bool)?
    var onInviteMembers: (@MainActor ([String]) async -> Bool)?

    private let mode: Mode

    private var groupName = ""
    private var groupDescription = ""
    private var participantEmails: [String] = []
    private var initialGroupName = ""
    private var initialGroupDescription = ""
    private var initialAvatarUrl: String?
    private var hasAvatarBeenEdited = false

    private var avatarPickerController: AvatarPickerController?
    private var avatarPayload: AvatarPayload?
    private var avatarCropHandler: AvatarCropHandler?

    private var bottomIslandBottomConstraint: NSLayoutConstraint?
    private var createButtonBottomConstraint: NSLayoutConstraint?
    private var keyboardBottomOverlap: CGFloat = 0

    private var isCreating = false
    private var isAvatarProcessing = false
    private var isParticipantsBatchUpdateInProgress = false

    // MARK: - Lifecycle
    init(mode: Mode = .create) {
        self.mode = mode

        switch mode {
        case .create:
            break
        case .edit(let initialData):
            groupName = initialData.name
            groupDescription = initialData.description ?? ""
            initialGroupName = initialData.name
            initialGroupDescription = initialData.description ?? ""
            let normalizedAvatarURL = initialData.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalizedAvatarURL, normalizedAvatarURL.isEmpty == false {
                initialAvatarUrl = normalizedAvatarURL
            } else {
                initialAvatarUrl = nil
            }
        case .inviteMembers:
            break
        }

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
        if usesAvatarSection {
            configureAvatarPicker()
        }
        configureKeyboardObservers()
        updateCreateButtonState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.presentationController?.delegate = self
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
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Private Methods
    private var visibleSections: [Section] {
        switch mode {
        case .create:
            return [.avatar, .name, .description, .divider, .participants]
        case .edit:
            return [.avatar, .name, .description]
        case .inviteMembers:
            return [.participants]
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .create:
            return "groupsCreationTitle".localized
        case .edit:
            return "groupsEditingTitle".localized
        case .inviteMembers:
            return "inviteParticipantsTitle".localized
        }
    }

    private var submitButtonTitleKey: String {
        switch mode {
        case .create:
            return "create"
        case .edit:
            return "edit"
        case .inviteMembers:
            return "invite"
        }
    }

    private var usesAvatarSection: Bool {
        visibleSections.contains(.avatar)
    }

    private var usesParticipantsSection: Bool {
        visibleSections.contains(.participants)
    }

    private func section(at index: Int) -> Section? {
        guard visibleSections.indices.contains(index) else { return nil }
        return visibleSections[index]
    }

    private func indexOfSection(_ section: Section) -> Int? {
        visibleSections.firstIndex(of: section)
    }

    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
        configureActions()
        setCreateButtonTitleVisible(true)
    }

    private func configureNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = navigationTitle
        titleLabel.textColor = .textSecondary
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        navigationItem.titleView = titleLabel

        let closeConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 17, weight: .semibold)
        )
        let closeAction = UIAction { [weak self] _ in
            self?.handleCloseTap()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark", withConfiguration: closeConfiguration)?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: closeAction
        )
        navigationItem.hidesBackButton = true
    }

    private func configureConstraints() {
        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.tableTopInset)
        tableBackgroundView.pinLeft(to: view.leadingAnchor)
        tableBackgroundView.pinRight(to: view.trailingAnchor)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)

        view.addSubview(bottomIslandView)
        bottomIslandView.pinLeft(to: view.leadingAnchor)
        bottomIslandView.pinRight(to: view.trailingAnchor)
        bottomIslandBottomConstraint = bottomIslandView.pinBottom(to: view.bottomAnchor)

        bottomIslandView.addSubview(createButton)
        createButton.pinTop(to: bottomIslandView.topAnchor, UIConstants.buttonVerticalInset)
        createButton.pinLeft(to: bottomIslandView.leadingAnchor, UIConstants.buttonHorizontalInset)
        createButton.pinRight(to: bottomIslandView.trailingAnchor, UIConstants.buttonHorizontalInset)
        createButtonBottomConstraint = createButton.pinBottom(to: bottomIslandView.bottomAnchor)

        createButton.addSubview(createButtonLoader)
        createButtonLoader.pinCenter(to: createButton)

        updateBottomIslandButtonInset()
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(TextInputTableViewCell.self, forCellReuseIdentifier: TextInputTableViewCell.reuseIdentifier)
        tableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        tableView.register(GroupCreationAvatarTableViewCell.self, forCellReuseIdentifier: GroupCreationAvatarTableViewCell.reuseIdentifier)
        tableView.register(
            GroupCreationParticipantsHeaderTableViewCell.self,
            forCellReuseIdentifier: GroupCreationParticipantsHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            GroupCreationParticipantEmailTableViewCell.self,
            forCellReuseIdentifier: GroupCreationParticipantEmailTableViewCell.reuseIdentifier
        )

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureActions() {
        createButton.addTarget(self, action: #selector(handleCreateTap), for: .touchUpInside)
    }

    private func configureAvatarPicker() {
        avatarPickerController = AvatarPickerController(
            avatarView: avatarPickerView,
            presentingViewController: self,
            interactor: self,
            initialAvatar: avatarPayload?.image,
            initialAvatarURL: initialAvatarUrl,
            onProcessingChanged: { [weak self] isProcessing in
                self?.setAvatarProcessingState(isProcessing)
            },
            onAvatarChanged: { [weak self] payload in
                guard let self else { return }

                if case .edit = self.mode {
                    self.hasAvatarBeenEdited = true
                }

                if let image = payload.image {
                    self.avatarPayload = (image: image, data: payload.data)
                } else {
                    self.avatarPayload = nil
                }
            },
            onCameraAccessDenied: { [weak self] in
                self?.presentCameraAccessDeniedSheet()
            }
        )
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
            selector: #selector(handleKeyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private var isKeyboardVisible: Bool {
        keyboardBottomOverlap > 0.5
    }

    private func keyboardCornerCoverInset(for overlap: CGFloat) -> CGFloat {
        min(UIConstants.keyboardCornerCoverInset, overlap)
    }

    private func updateBottomIslandButtonInset() {
        let bottomInset: CGFloat

        if isKeyboardVisible {
            let cornerCoverInset = keyboardCornerCoverInset(for: keyboardBottomOverlap)
            bottomInset = UIConstants.keyboardButtonBottomInset + cornerCoverInset
        } else {
            bottomInset = view.safeAreaInsets.bottom + UIConstants.buttonBottomInset
        }

        createButtonBottomConstraint?.constant = -bottomInset
    }

    private func updateTableInsetsForBottomIsland() {
        let visibleIslandHeight = max(0, view.bounds.maxY - bottomIslandView.frame.minY)
        let bottomInset = visibleIslandHeight + UIConstants.tableBottomSpacing
        tableView.contentInset.bottom = bottomInset
        tableView.verticalScrollIndicatorInsets.bottom = bottomInset
    }

    private func setCreateButtonTitleVisible(_ isVisible: Bool) {
        let title = isVisible ? createButtonTitle : nil
        createButton.setAttributedTitle(title, for: .normal)
        createButton.setAttributedTitle(title, for: .disabled)
    }

    private func setCreateButtonLoading(_ isLoading: Bool) {
        setCreateButtonTitleVisible(isLoading == false)
        if isLoading {
            createButtonLoader.startAnimating()
        } else {
            createButtonLoader.stopAnimating()
        }
    }

    private func updateCreateButtonState() {
        let normalizedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasInvalidEnteredEmails = participantEmails.contains { rawEmail in
            let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
            return email.isEmpty == false && email.isValidEmail == false
        }

        let hasAtLeastOneEmail = sanitizedParticipantEmails.isEmpty == false
        let isEnabled: Bool
        switch mode {
        case .create, .edit:
            isEnabled = normalizedName.isEmpty == false
                && hasInvalidEnteredEmails == false
                && isCreating == false
                && isAvatarProcessing == false
        case .inviteMembers:
            isEnabled = hasAtLeastOneEmail
                && hasInvalidEnteredEmails == false
                && isCreating == false
                && isAvatarProcessing == false
        }

        createButton.isEnabled = isEnabled
        createButton.alpha = isEnabled ? 1 : 0.6
    }

    private func updateModalInPresentationState() {
        isModalInPresentation = isCreating || isAvatarProcessing
    }

    private func reloadInputRows() {
        var indexPaths: [IndexPath] = []

        if let nameSectionIndex = indexOfSection(.name) {
            indexPaths.append(IndexPath(row: 1, section: nameSectionIndex))
        }
        if let descriptionSectionIndex = indexOfSection(.description) {
            indexPaths.append(IndexPath(row: 1, section: descriptionSectionIndex))
        }

        guard indexPaths.isEmpty == false else { return }
        tableView.reloadRows(at: indexPaths, with: .none)
    }

    private func setAvatarProcessingState(_ isProcessing: Bool) {
        guard isAvatarProcessing != isProcessing else { return }
        isAvatarProcessing = isProcessing

        setCreateButtonLoading(isProcessing)
        reloadInputRows()
        updateModalInPresentationState()
        updateCreateButtonState()
    }

    private func presentCameraAccessDeniedSheet() {
        showInfoBottomSheet(
            title: "attentionTitle".localized,
            description: "cameraAccessDeniedDescription".localized,
            buttonTitle: "ok".localized
        )
    }

    private func handleAddParticipantTap() {
        guard usesParticipantsSection else { return }
        guard isParticipantsBatchUpdateInProgress == false else { return }
        guard isCreating == false, isAvatarProcessing == false else { return }
        guard let participantsSectionIndex = indexOfSection(.participants) else { return }

        isParticipantsBatchUpdateInProgress = true

        let insertionIndex = participantEmails.count
        let tableIndexPath = IndexPath(row: insertionIndex + 1, section: participantsSectionIndex)

        tableView.performBatchUpdates {
            participantEmails.insert("", at: insertionIndex)
            tableView.insertRows(at: [tableIndexPath], with: .automatic)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isParticipantsBatchUpdateInProgress = false
            self.tableView.scrollToRow(at: tableIndexPath, at: .bottom, animated: true)
            self.updateCreateButtonState()
        }
    }

    private func handleDeleteParticipant(at index: Int) {
        guard usesParticipantsSection else { return }
        guard isParticipantsBatchUpdateInProgress == false else { return }
        guard participantEmails.indices.contains(index) else { return }
        guard let participantsSectionIndex = indexOfSection(.participants) else { return }

        isParticipantsBatchUpdateInProgress = true
        let tableIndexPath = IndexPath(row: index + 1, section: participantsSectionIndex)

        tableView.performBatchUpdates {
            participantEmails.remove(at: index)
            tableView.deleteRows(at: [tableIndexPath], with: .automatic)
        } completion: { [weak self] _ in
            guard let self else { return }
            self.isParticipantsBatchUpdateInProgress = false
            self.updateCreateButtonState()
        }
    }

    private func handleParticipantEmailChanged(at index: Int, value: String) {
        guard participantEmails.indices.contains(index) else { return }
        participantEmails[index] = value
        updateCreateButtonState()
    }

    private var sanitizedParticipantEmails: [String] {
        participantEmails
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    private var hasUnsavedChanges: Bool {
        switch mode {
        case .create:
            if groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                return true
            }

            if groupDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                return true
            }

            if avatarPayload != nil {
                return true
            }

            return participantEmails.contains {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }

        case .edit:
            let normalizedCurrentName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedInitialName = initialGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedCurrentName != normalizedInitialName {
                return true
            }

            let normalizedCurrentDescription = groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedInitialDescription = initialGroupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            if normalizedCurrentDescription != normalizedInitialDescription {
                return true
            }

            if hasAvatarBeenEdited == false {
                return false
            }

            if avatarPayload != nil {
                return true
            }

            return initialAvatarUrl != nil

        case .inviteMembers:
            return participantEmails.contains {
                $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            }
        }
    }

    private func handleDismissAttemptWithUnsavedChanges() {
        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: "inputBottomSheetExitWithUnsavedChangesMessage".localized,
            cancelTitle: "cancel".localized,
            confirmTitle: "exit".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    private func handleCloseTap() {
        guard isCreating == false, isAvatarProcessing == false else { return }

        if hasUnsavedChanges {
            handleDismissAttemptWithUnsavedChanges()
        } else {
            dismiss(animated: true)
        }
    }

    private func scrollFirstResponderAboveKeyboard() {
        guard keyboardBottomOverlap > 0 else { return }
        guard let firstResponder = findFirstResponder(in: tableView) else { return }

        let responderFrame = firstResponder.convert(firstResponder.bounds, to: tableView)
        tableView.scrollRectToVisible(
            responderFrame.insetBy(dx: 0, dy: -12),
            animated: true
        )
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

    @objc
    private func handleKeyboardWillChangeFrame(_ notification: Notification) {
        guard let change = KeyboardChange(notification) else { return }

        let keyboardFrame = view.convert(change.endFrame, from: nil)
        let overlap = max(0, view.bounds.maxY - keyboardFrame.minY)
        let cornerCoverInset = keyboardCornerCoverInset(for: overlap)
        let targetOffset = max(0, overlap - cornerCoverInset)

        keyboardBottomOverlap = overlap
        bottomIslandBottomConstraint?.constant = -targetOffset
        updateBottomIslandButtonInset()

        UIView.animate(withDuration: change.duration, delay: 0, options: change.options) {
            self.view.layoutIfNeeded()
            self.updateTableInsetsForBottomIsland()
        } completion: { _ in
            self.scrollFirstResponderAboveKeyboard()
        }
    }

    // MARK: - Actions
    @objc
    private func handleCreateTap() {
        guard isCreating == false else { return }

        isCreating = true
        updateModalInPresentationState()
        updateCreateButtonState()

        Task { @MainActor [weak self] in
            guard let self else { return }

            let isSuccessful: Bool
            switch self.mode {
            case .create:
                let normalizedGroupName = self.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalizedGroupName.isEmpty == false else {
                    self.isCreating = false
                    self.updateModalInPresentationState()
                    self.updateCreateButtonState()
                    return
                }

                let normalizedDescription = self.groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                let descriptionToCreate = normalizedDescription.isEmpty ? nil : normalizedDescription
                let participantEmailsToCreate = self.sanitizedParticipantEmails.map { String($0) }
                let avatarDataToUpload = self.avatarPayload?.data
                isSuccessful = await self.onCreateGroup?(
                    normalizedGroupName,
                    descriptionToCreate,
                    participantEmailsToCreate,
                    avatarDataToUpload
                ) ?? false

            case .edit:
                let normalizedGroupName = self.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalizedGroupName.isEmpty == false else {
                    self.isCreating = false
                    self.updateModalInPresentationState()
                    self.updateCreateButtonState()
                    return
                }

                let normalizedDescription = self.groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                let descriptionToUpdate = normalizedDescription.isEmpty ? nil : normalizedDescription

                let avatarAction: EditGroupRequest.AvatarAction
                if self.hasAvatarBeenEdited == false {
                    avatarAction = .unchanged
                } else if let avatarData = self.avatarPayload?.data {
                    avatarAction = .update(data: avatarData)
                } else if self.initialAvatarUrl != nil {
                    avatarAction = .remove
                } else {
                    avatarAction = .unchanged
                }

                isSuccessful = await self.onEditGroup?(
                    EditGroupRequest(
                        name: normalizedGroupName,
                        description: descriptionToUpdate,
                        avatarAction: avatarAction
                    )
                ) ?? false

            case .inviteMembers:
                let emails = self.sanitizedParticipantEmails.map { String($0) }
                guard emails.isEmpty == false else {
                    self.isCreating = false
                    self.updateModalInPresentationState()
                    self.updateCreateButtonState()
                    return
                }
                isSuccessful = await self.onInviteMembers?(emails) ?? false
            }

            if isSuccessful {
                self.dismiss(animated: true)
                return
            }

            self.isCreating = false
            self.updateModalInPresentationState()
            self.updateCreateButtonState()
        }
    }
}

// MARK: - UITableViewDataSource
extension GroupCreationBottomSheetViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        visibleSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        guard let section = section(at: sectionIndex) else { return 0 }

        switch section {
        case .avatar:
            return 1
        case .name:
            return 2
        case .description:
            return 2
        case .divider:
            return 1
        case .participants:
            return 1 + participantEmails.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = section(at: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .avatar:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupCreationAvatarTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? GroupCreationAvatarTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(avatarView: avatarPickerView)
            return cell

        case .name:
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: HeaderTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? HeaderTableViewCell else {
                    return UITableViewCell()
                }

                cell.configure(title: "title".localized)
                return cell
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextInputTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TextInputTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: groupName,
                placeholder: "enterTitlePlaceholder".localized,
                isLoading: isAvatarProcessing
            )
            cell.onTextChanged = { [weak self] text in
                self?.groupName = text
                self?.updateCreateButtonState()
            }
            return cell

        case .description:
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: HeaderTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? HeaderTableViewCell else {
                    return UITableViewCell()
                }

                cell.configure(title: "description".localized)
                return cell
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TextInputTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? TextInputTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                title: groupDescription,
                placeholder: "enterDescriptionPlaceholder".localized,
                isLoading: isAvatarProcessing
            )
            cell.onTextChanged = { [weak self] text in
                self?.groupDescription = text
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

        case .participants:
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: GroupCreationParticipantsHeaderTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? GroupCreationParticipantsHeaderTableViewCell else {
                    return UITableViewCell()
                }

                cell.configure(title: "participants".localized)
                cell.onAddTap = { [weak self] in
                    self?.handleAddParticipantTap()
                }
                cell.onInfoTap = { [weak self] in
                    guard let self else { return }
                    self.showInfoBottomSheet(
                        title: "participants".localized,
                        description: UIConstants.participantsInfoDescription,
                        buttonTitle: "ok".localized
                    )
                }
                return cell
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupCreationParticipantEmailTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? GroupCreationParticipantEmailTableViewCell else {
                return UITableViewCell()
            }

            let participantIndex = indexPath.row - 1
            guard participantEmails.indices.contains(participantIndex) else {
                return UITableViewCell()
            }

            cell.configure(email: participantEmails[participantIndex])
            cell.onTextChanged = { [weak self, weak cell] value in
                guard
                    let self,
                    let cell,
                    let actualIndexPath = self.tableView.indexPath(for: cell)
                else {
                    return
                }

                self.handleParticipantEmailChanged(at: actualIndexPath.row - 1, value: value)
            }
            cell.onDeleteTap = { [weak self, weak cell] in
                guard
                    let self,
                    let cell,
                    let actualIndexPath = self.tableView.indexPath(for: cell)
                else {
                    return
                }

                self.handleDeleteParticipant(at: actualIndexPath.row - 1)
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension GroupCreationBottomSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = section(at: indexPath.section) else {
            return UITableView.automaticDimension
        }

        switch section {
        case .avatar:
            return UIConstants.avatarRowHeight
        case .name, .description:
            return indexPath.row == 0 ? UIConstants.headerRowHeight : UITableView.automaticDimension
        case .divider:
            return 1
        case .participants:
            return indexPath.row == 0
                ? UIConstants.participantsHeaderHeight
                : UIConstants.participantsRowHeight
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = section(at: indexPath.section) else {
            return UITableView.automaticDimension
        }

        switch section {
        case .avatar:
            return UIConstants.avatarRowHeight
        case .name, .description:
            return indexPath.row == 0 ? UIConstants.headerRowHeight : 54
        case .divider:
            return 1
        case .participants:
            return indexPath.row == 0
                ? UIConstants.participantsHeaderHeight
                : UIConstants.participantsRowHeight
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let currentSection = self.section(at: section) else { return 0 }
        guard currentSection == .description else { return 0 }

        let nextSectionIndex = section + 1
        guard nextSectionIndex < visibleSections.count else { return 0 }
        return visibleSections[nextSectionIndex] == .divider ? UIConstants.descriptionToDividerSpacing : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}

// MARK: - AlertPresenting
extension GroupCreationBottomSheetViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}

// MARK: - InfoBottomSheetPresenting
extension GroupCreationBottomSheetViewController: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        self
    }
}

// MARK: - AvatarFlowInteracting
extension GroupCreationBottomSheetViewController: AvatarFlowInteracting {
    func presentAvatarCrop(
        image: UIImage,
        onFinish: @escaping @MainActor (UIImage?) -> Void
    ) async {
        var config = Mantis.Config()
        config.presetFixedRatioType = .alwaysUsingOnePresetFixedRatio(ratio: 1)
        config.cropViewConfig.cropShapeType = .circle(maskOnly: true)
        config.cropViewConfig.showAttachedRotationControlView = false

        let cropViewController = Mantis.cropViewController(image: image, config: config)
        cropViewController.modalPresentationStyle = .fullScreen

        avatarCropHandler = AvatarCropHandler(onFinish: { [weak self] croppedImage in
            onFinish(croppedImage)
            self?.avatarCropHandler = nil
        })
        cropViewController.delegate = avatarCropHandler
        present(cropViewController, animated: true)
    }

    func presentAvatarDeleteConfirmation(onConfirm: @escaping @MainActor () -> Void) async {
        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: "avatarDeleteConfirmationMessage".localized,
            cancelTitle: "cancel".localized,
            confirmTitle: "delete".localized,
            confirmStyle: .destructive
        ) {
            onConfirm()
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension GroupCreationBottomSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        isCreating == false && isAvatarProcessing == false && hasUnsavedChanges == false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        guard isCreating == false, isAvatarProcessing == false else { return }

        if hasUnsavedChanges {
            handleDismissAttemptWithUnsavedChanges()
        }
    }
}

private extension GroupCreationBottomSheetViewController {
    var createButtonTitle: NSAttributedString {
        NSAttributedString(
            string: submitButtonTitleKey.localized,
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )
    }
}

private final class GroupCreationAvatarTableViewCell: UITableViewCell {
    // MARK: - Constants
    static let reuseIdentifier = "GroupCreationAvatarTableViewCell"

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
    func configure(avatarView: AvatarPickerView) {
        guard avatarView.superview !== contentView else { return }

        avatarView.removeFromSuperview()
        contentView.addSubview(avatarView)
        avatarView.pinCenterX(to: contentView.centerXAnchor)
        avatarView.pinTop(to: contentView.topAnchor, 10)
        avatarView.pinBottom(to: contentView.bottomAnchor, 10)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
}

private final class GroupCreationParticipantsHeaderTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let headerView = GroupCreationParticipantsHeaderView()

    // MARK: - Constants
    static let reuseIdentifier = "GroupCreationParticipantsHeaderTableViewCell"

    // MARK: - Properties
    var onAddTap: (() -> Void)? {
        didSet {
            headerView.onAddTap = onAddTap
        }
    }
    var onInfoTap: (() -> Void)? {
        didSet {
            headerView.onInfoTap = onInfoTap
        }
    }

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
        onInfoTap = nil
    }

    // MARK: - Methods
    func configure(title: String) {
        headerView.configure(title: title)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(headerView)
        headerView.pinTop(to: contentView.topAnchor)
        headerView.pinBottom(to: contentView.bottomAnchor)
        headerView.pinLeft(to: contentView.leadingAnchor)
        headerView.pinRight(to: contentView.trailingAnchor)
    }
}

private final class GroupCreationParticipantsHeaderView: UIView {
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

    private let infoButton: UIButton = {
        let button = UIButton(type: .system)
        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 12, weight: .medium)
        )
        let image = UIImage(systemName: "info.circle", withConfiguration: symbolConfiguration)?
            .withTintColor(.textSecondary, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.backgroundColor = .clear
        return button
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
    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let topOffset: CGFloat = 4
    }

    // MARK: - Properties
    var onAddTap: (() -> Void)?
    var onInfoTap: (() -> Void)?

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(title: String) {
        titleLabel.text = title
    }

    // MARK: - Private Methods
    private func configureUI() {
        addSubview(titleLabel)
        titleLabel.pinCenterY(to: centerYAnchor, UIConstants.topOffset)
        titleLabel.pinLeft(to: safeAreaLayoutGuide.leadingAnchor, UIConstants.horizontalInset)

        addSubview(infoButton)
        infoButton.pinCenterY(to: titleLabel)
        infoButton.pinLeft(to: titleLabel.trailingAnchor, 6)

        addSubview(addButtonContainerView)
        addButtonContainerView.pinRight(to: safeAreaLayoutGuide.trailingAnchor, UIConstants.horizontalInset)
        addButtonContainerView.pinCenterY(to: titleLabel)

        addButtonContainerView.addSubview(addButtonGlassBackgroundView)
        addButtonGlassBackgroundView.pin(to: addButtonContainerView)
        configureGlassBackgroundView(addButtonGlassBackgroundView)

        addButtonGlassBackgroundView.contentView.addSubview(addButton)
        addButton.pin(to: addButtonGlassBackgroundView.contentView)
        addButton.addTarget(self, action: #selector(handleAddTap), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(handleInfoTap), for: .touchUpInside)
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

    @objc
    private func handleInfoTap() {
        onInfoTap?()
    }
}

private final class GroupCreationParticipantEmailTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let emailTextField: UITextField = {
        let field = UITextField()
        field.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        field.textColor = .textSecondary
        field.attributedPlaceholder = NSAttributedString(
            string: "groupsEnterEmailPlaceholder".localized,
            attributes: [
                .foregroundColor: UIColor.dividerPrimary,
                .font: UIFont.systemFont(ofSize: 17, weight: .medium)
            ]
        )
        field.borderStyle = .none
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.textContentType = .emailAddress
        return field
    }()

    private let invalidEmailImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
        let image = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: configuration)?
            .withTintColor(.backgroundRedSecondary, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        imageView.alpha = 0
        return imageView
    }()

    // MARK: - Constants
    static let reuseIdentifier = "GroupCreationParticipantEmailTableViewCell"

    private enum UIConstants {
        static let leadingInset: CGFloat = 24
        static let trailingInset: CGFloat = 24
        static let invalidIconSize: CGFloat = 11
        static let invalidIconRightSpacing: CGFloat = 4
    }

    // MARK: - Properties
    var onTextChanged: ((String) -> Void)?
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
        onDeleteTap = nil
    }

    // MARK: - Methods
    func configure(email: String) {
        emailTextField.text = email
        updateInvalidEmailIndicator(for: email, forceDisplay: false, animated: false)
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(emailTextField)
        emailTextField.pinTop(to: contentView.topAnchor)
        emailTextField.pinBottom(to: contentView.bottomAnchor)
        emailTextField.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.leadingInset)
        emailTextField.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.trailingInset)
        emailTextField.addTarget(self, action: #selector(handleEditingChanged), for: .editingChanged)
        emailTextField.delegate = self

        contentView.addSubview(invalidEmailImageView)
        invalidEmailImageView.pinCenterY(to: emailTextField.centerYAnchor)
        invalidEmailImageView.pinRight(
            to: emailTextField.leadingAnchor,
            UIConstants.invalidIconRightSpacing
        )
        invalidEmailImageView.setWidth(UIConstants.invalidIconSize)
        invalidEmailImageView.setHeight(UIConstants.invalidIconSize)

        let contextInteraction = UIContextMenuInteraction(delegate: self)
        contentView.addInteraction(contextInteraction)
    }

    private func updateInvalidEmailIndicator(
        for rawEmail: String,
        forceDisplay: Bool,
        animated: Bool
    ) {
        let email = rawEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldShow = forceDisplay && email.isEmpty == false && email.isValidEmail == false
        let targetAlpha: CGFloat = shouldShow ? 1 : 0

        if animated {
            if shouldShow {
                invalidEmailImageView.isHidden = false
            }

            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseInOut]) {
                self.invalidEmailImageView.alpha = targetAlpha
            } completion: { _ in
                self.invalidEmailImageView.isHidden = shouldShow == false
            }
            return
        }

        invalidEmailImageView.alpha = targetAlpha
        invalidEmailImageView.isHidden = shouldShow == false
    }

    // MARK: - Actions
    @objc
    private func handleEditingChanged() {
        let text = emailTextField.text ?? ""
        let isValidEmail = text.trimmingCharacters(in: .whitespacesAndNewlines).isValidEmail
        if isValidEmail {
            updateInvalidEmailIndicator(
                for: text,
                forceDisplay: false,
                animated: true
            )
        }
        onTextChanged?(text)
    }
}

// MARK: - UITextFieldDelegate
extension GroupCreationParticipantEmailTableViewCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        updateInvalidEmailIndicator(
            for: textField.text ?? "",
            forceDisplay: true,
            animated: true
        )
    }
}

// MARK: - UIContextMenuInteractionDelegate
extension GroupCreationParticipantEmailTableViewCell: UIContextMenuInteractionDelegate {
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
