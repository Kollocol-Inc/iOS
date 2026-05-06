//
//  GroupPreviewViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import UIKit
import ShimmerView

final class GroupPreviewViewController: UIViewController {
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

    private let navigationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
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
        stackView.spacing = 0
        stackView.alignment = .center
        return stackView
    }()

    private let avatarMenuContainerView = UIView()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(image: .groupsAvatarPlaceholder)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 18
        imageView.layer.borderWidth = 1.5
        imageView.backgroundColor = .backgroundSecondary
        return imageView
    }()

    private let avatarMenuButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let tableTopInset: CGFloat = 8
        static let avatarSize: CGFloat = 36
        static let backButtonSize: CGFloat = 17
        static let headerRowHeight: CGFloat = 46
        static let participantRowHeight: CGFloat = 54
        static let inviteButtonRowHeight: CGFloat = 54
        static let dividerRowHeight: CGFloat = 1
        static let shimmerRowsPerSection: Int = 4
    }

    private enum TableSection: Int, CaseIterable {
        case members
        case invited
        case actions

        var title: String {
            switch self {
            case .members:
                return "participants".localized
            case .invited:
                return "groupsInvited".localized
            case .actions:
                return ""
            }
        }

        var emptyText: String {
            switch self {
            case .members:
                return "noParticipants".localized
            case .invited:
                return "groupsNoInvitedParticipants".localized
            case .actions:
                return ""
            }
        }
    }

    // MARK: - Properties
    private let interactor: GroupPreviewInteractor
    private let initialData: GroupPreviewModels.InitialData
    private var groupData: GroupPreviewModels.ViewData?

    private var members: [GroupPreviewModels.ParticipantViewData] = []
    private var invitedMembers: [GroupPreviewModels.ParticipantViewData] = []
    private var pendingParticipantActionEmails = Set<String>()
    private var isParticipantsLoading = false
    private var participantsShimmerEffectBeginTime: CFTimeInterval = 0

    // MARK: - Lifecycle
    init(
        interactor: GroupPreviewInteractor,
        initialData: GroupPreviewModels.InitialData
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
        configureUI()
        configureNavigationBar()
        displayGroup(
            GroupPreviewModels.ViewData(
                groupId: initialData.groupId,
                title: initialData.title,
                subtitle: initialData.subtitle,
                avatarUrl: initialData.avatarUrl,
                ownerId: initialData.ownerId,
                isCurrentUserOwner: initialData.isCurrentUserOwner
            )
        )
        startParticipantsLoadingShimmer()

        Task {
            await interactor.handleViewDidLoad()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateAvatarBorderColor()
        guard isParticipantsLoading else { return }
        tableView.reloadData()
    }

    // MARK: - Methods
    @MainActor
    func displayGroup(_ data: GroupPreviewModels.ViewData) {
        groupData = data

        let normalizedSubtitle = data.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedSubtitle, normalizedSubtitle.isEmpty == false {
            navigationTitleLabel.text = data.title
            navigationTitleLabel.textColor = .textPrimary
            navigationSubtitleLabel.text = normalizedSubtitle
            navigationSubtitleLabel.isHidden = false
        } else {
            navigationTitleLabel.text = data.title
            navigationTitleLabel.textColor = .textSecondary
            navigationSubtitleLabel.text = nil
            navigationSubtitleLabel.isHidden = true
        }

        avatarImageView.setImage(url: data.avatarUrl, placeholder: .groupsAvatarPlaceholder)
        configureAvatarMenu()
    }

    @MainActor
    func displayParticipants(_ data: GroupPreviewModels.ParticipantsViewData) {
        stopParticipantsLoadingShimmer()
        members = data.members
        invitedMembers = data.invitedMembers
        tableView.reloadData()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
        updateAvatarBorderColor()
    }

    private func configureConstraints() {
        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.tableTopInset)
        tableBackgroundView.pinLeft(to: view.leadingAnchor)
        tableBackgroundView.pinRight(to: view.trailingAnchor)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)
    }

    private func configureTableView() {
        tableView.register(
            GroupPreviewParticipantsHeaderTableViewCell.self,
            forCellReuseIdentifier: GroupPreviewParticipantsHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            GroupPreviewParticipantTableViewCell.self,
            forCellReuseIdentifier: GroupPreviewParticipantTableViewCell.reuseIdentifier
        )
        tableView.register(
            GroupPreviewParticipantShimmerTableViewCell.self,
            forCellReuseIdentifier: GroupPreviewParticipantShimmerTableViewCell.reuseIdentifier
        )
        tableView.register(
            EmptyStateTableViewCell.self,
            forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier
        )
        tableView.register(
            DividerTableViewCell.self,
            forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier
        )
        tableView.register(
            GroupPreviewInviteParticipantsTableViewCell.self,
            forCellReuseIdentifier: GroupPreviewInviteParticipantsTableViewCell.reuseIdentifier
        )

        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureNavigationBar() {
        navigationItem.titleView = navigationTitleStackView
        navigationItem.hidesBackButton = true

        let backConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: UIConstants.backButtonSize, weight: .semibold)
        )
        let backAction = UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward", withConfiguration: backConfiguration)?
                .withTintColor(.textSecondary, renderingMode: .alwaysOriginal),
            primaryAction: backAction
        )

        avatarMenuContainerView.setWidth(UIConstants.avatarSize)
        avatarMenuContainerView.setHeight(UIConstants.avatarSize)

        avatarMenuContainerView.addSubview(avatarImageView)
        avatarImageView.pin(to: avatarMenuContainerView)

        avatarMenuContainerView.addSubview(avatarMenuButton)
        avatarMenuButton.pin(to: avatarMenuContainerView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: avatarMenuContainerView)
    }

    private func updateAvatarBorderColor() {
        avatarImageView.layer.borderColor = UIColor.accentPrimary.resolvedColor(with: traitCollection).cgColor
    }

    private func configureAvatarMenu() {
        guard let groupData else { return }

        if groupData.isCurrentUserOwner {
            let editAction = UIAction(
                title: "edit".localized,
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                self?.presentEditGroupSheet()
            }

            let inviteAction = UIAction(
                title: "inviteParticipants".localized,
                image: UIImage(systemName: "person.2.badge.plus.fill")
            ) { [weak self] _ in
                self?.presentInviteParticipantsSheet()
            }

            let deleteAction = UIAction(
                title: "deleteGroup".localized,
                image: UIImage(systemName: "trash.fill"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.presentDeleteGroupConfirmationAlert()
            }

            avatarMenuButton.menu = UIMenu(
                options: .displayInline,
                children: [editAction, inviteAction, deleteAction]
            )
            return
        }

        let leaveAction = UIAction(
            title: "leaveGroup".localized,
            image: UIImage(systemName: "door.right.hand.open"),
            attributes: .destructive
        ) { [weak self] _ in
            self?.presentLeaveGroupConfirmationAlert()
        }

        avatarMenuButton.menu = UIMenu(options: .displayInline, children: [leaveAction])
    }

    private func presentEditGroupSheet() {
        guard let groupData else { return }

        let viewController = GroupCreationBottomSheetViewController(
            mode: .edit(
                initialData: .init(
                    avatarUrl: groupData.avatarUrl,
                    name: groupData.title,
                    description: groupData.subtitle
                )
            )
        )

        viewController.onEditGroup = { [weak self] request in
            guard let self else { return false }

            let interactorRequest = GroupPreviewModels.EditGroupRequest(
                name: request.name,
                description: request.description,
                avatarAction: request.avatarAction.toPreviewAvatarAction()
            )
            return await self.interactor.handleEditGroup(interactorRequest)
        }

        presentBottomSheet(viewController)
    }

    private func presentInviteParticipantsSheet() {
        let viewController = GroupCreationBottomSheetViewController(mode: .inviteMembers)
        viewController.onInviteMembers = { [weak self] emails in
            guard let self else { return false }
            return await self.interactor.handleInviteMembers(emails: emails)
        }

        presentBottomSheet(viewController)
    }

    private func presentBottomSheet(_ viewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet

        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }

        present(navigationController, animated: true)
    }

    private func presentLeaveGroupConfirmationAlert() {
        guard let groupData else { return }

        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: String(format: "groupLeaveConfirmationFormat".localized, groupData.title),
            cancelTitle: "cancel".localized,
            confirmTitle: "leave".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            Task {
                await self?.interactor.handleLeaveGroup()
            }
        }
    }

    private func presentDeleteGroupConfirmationAlert() {
        guard let groupData else { return }

        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: String(format: "groupDeleteConfirmationFormat".localized, groupData.title),
            cancelTitle: "cancel".localized,
            confirmTitle: "delete".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            Task {
                await self?.interactor.handleDeleteGroup()
            }
        }
    }

    private func participants(for section: TableSection) -> [GroupPreviewModels.ParticipantViewData] {
        switch section {
        case .members:
            return members
        case .invited:
            return invitedMembers
        case .actions:
            return []
        }
    }

    private func setParticipants(_ value: [GroupPreviewModels.ParticipantViewData], for section: TableSection) {
        switch section {
        case .members:
            members = value
        case .invited:
            invitedMembers = value
        case .actions:
            break
        }
    }

    private func indexPath(for participant: GroupPreviewModels.ParticipantViewData, section: TableSection) -> IndexPath? {
        let participants = participants(for: section)
        guard let index = participants.firstIndex(where: { $0.id == participant.id }) else {
            return nil
        }

        return IndexPath(row: index + 1, section: section.rawValue)
    }

    private func isPending(email: String?) -> Bool {
        guard let email else { return false }
        return pendingParticipantActionEmails.contains(email.normalizedEmail)
    }

    private func removeParticipant(email: String, from section: TableSection) {
        let normalizedEmail = email.normalizedEmail
        var updatedParticipants = participants(for: section)

        guard let removedIndex = updatedParticipants.firstIndex(where: {
            $0.email?.normalizedEmail == normalizedEmail
        }) else {
            tableView.reloadData()
            return
        }

        let wasLastParticipant = updatedParticipants.count == 1
        updatedParticipants.remove(at: removedIndex)
        setParticipants(updatedParticipants, for: section)

        let deletedRowIndexPath = IndexPath(row: removedIndex + 1, section: section.rawValue)
        let headerRowIndexPath = IndexPath(row: 0, section: section.rawValue)

        tableView.performBatchUpdates {
            tableView.deleteRows(at: [deletedRowIndexPath], with: .automatic)
            if wasLastParticipant {
                let emptyRowIndexPath = IndexPath(row: 1, section: section.rawValue)
                tableView.insertRows(at: [emptyRowIndexPath], with: .fade)
            }
            tableView.reloadRows(at: [headerRowIndexPath], with: .none)
        }
    }

    private func handleParticipantAction(
        participant: GroupPreviewModels.ParticipantViewData,
        section: TableSection
    ) {
        switch participant.rightAccessory {
        case .kick:
            presentKickConfirmationAlert(participant: participant, section: section)

        case .removeInvite:
            executeCancelInvite(for: participant, section: section)

        case .none, .crown, .you:
            break
        }
    }

    private func presentKickConfirmationAlert(
        participant: GroupPreviewModels.ParticipantViewData,
        section: TableSection
    ) {
        showConfirmationAlert(
            title: "attentionTitle".localized,
            message: String(
                format: "groupKickParticipantConfirmationFormat".localized,
                participant.fullName
            ),
            cancelTitle: "cancel".localized,
            confirmTitle: "kick".localized,
            confirmStyle: .destructive
        ) { [weak self] in
            self?.executeKick(for: participant, section: section)
        }
    }

    private func executeKick(
        for participant: GroupPreviewModels.ParticipantViewData,
        section: TableSection
    ) {
        guard let email = participant.email?.normalizedEmail, email.isEmpty == false else { return }
        guard pendingParticipantActionEmails.contains(email) == false else { return }

        pendingParticipantActionEmails.insert(email)
        if let rowToReload = indexPath(for: participant, section: section) {
            tableView.reloadRows(at: [rowToReload], with: .none)
        }

        Task {
            let success = await interactor.handleKickMember(email: email)
            await MainActor.run {
                self.pendingParticipantActionEmails.remove(email)
                if success {
                    self.removeParticipant(email: email, from: section)
                } else if let rowToReload = self.indexPath(for: participant, section: section) {
                    self.tableView.reloadRows(at: [rowToReload], with: .none)
                }
            }
        }
    }

    private func executeCancelInvite(
        for participant: GroupPreviewModels.ParticipantViewData,
        section: TableSection
    ) {
        guard let email = participant.email?.normalizedEmail, email.isEmpty == false else { return }
        guard pendingParticipantActionEmails.contains(email) == false else { return }

        pendingParticipantActionEmails.insert(email)
        if let rowToReload = indexPath(for: participant, section: section) {
            tableView.reloadRows(at: [rowToReload], with: .none)
        }

        Task {
            let success = await interactor.handleCancelInvite(email: email)
            await MainActor.run {
                self.pendingParticipantActionEmails.remove(email)
                if success {
                    self.removeParticipant(email: email, from: section)
                } else if let rowToReload = self.indexPath(for: participant, section: section) {
                    self.tableView.reloadRows(at: [rowToReload], with: .none)
                }
            }
        }
    }

    private var effectiveShimmerTraitCollection: UITraitCollection {
        view.window?.traitCollection ?? traitCollection
    }

    private func startParticipantsLoadingShimmer() {
        guard isParticipantsLoading == false else { return }
        isParticipantsLoading = true
        participantsShimmerEffectBeginTime = CACurrentMediaTime()
        tableView.reloadData()
    }

    private func stopParticipantsLoadingShimmer() {
        guard isParticipantsLoading else { return }
        isParticipantsLoading = false
    }

    private func makeParticipantsShimmerStyle() -> ShimmerViewStyle {
        let traitCollection = effectiveShimmerTraitCollection
        return ShimmerViewStyle(
            baseColor: UIColor.backgroundCardPrimary.resolvedColor(with: traitCollection),
            highlightColor: UIColor.backgroundPrimary.resolvedColor(with: traitCollection),
            duration: 1.2,
            interval: 0.4,
            effectSpan: .points(120),
            effectAngle: 0 * CGFloat.pi
        )
    }
}

// MARK: - UITableViewDataSource
extension GroupPreviewViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        TableSection.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let tableSection = TableSection(rawValue: section) else { return 0 }
        if tableSection == .actions {
            guard groupData?.isCurrentUserOwner == true else { return 0 }
            return 2
        }
        if isParticipantsLoading {
            return UIConstants.shimmerRowsPerSection + 1
        }

        let rows = participants(for: tableSection)
        return rows.isEmpty ? 2 : rows.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tableSection = TableSection(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        let sectionParticipants = participants(for: tableSection)
        if tableSection == .actions {
            if indexPath.row == 0 {
                guard let cell = tableView.dequeueReusableCell(
                    withIdentifier: DividerTableViewCell.reuseIdentifier,
                    for: indexPath
                ) as? DividerTableViewCell else {
                    return UITableViewCell()
                }
                return cell
            }

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupPreviewInviteParticipantsTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? GroupPreviewInviteParticipantsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: "inviteParticipants".localized) { [weak self] in
                self?.presentInviteParticipantsSheet()
            }
            return cell
        }

        if indexPath.row == 0 {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupPreviewParticipantsHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? GroupPreviewParticipantsHeaderTableViewCell else {
                return UITableViewCell()
            }

            let counter: Int? = isParticipantsLoading
                ? nil
                : (sectionParticipants.isEmpty ? nil : sectionParticipants.count)
            cell.configure(title: tableSection.title, count: counter)
            return cell
        }

        if isParticipantsLoading {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: GroupPreviewParticipantShimmerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? GroupPreviewParticipantShimmerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                shimmerStyle: makeParticipantsShimmerStyle(),
                effectBeginTime: participantsShimmerEffectBeginTime
            )
            return cell
        }

        if sectionParticipants.isEmpty {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: EmptyStateTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: tableSection.emptyText)
            return cell
        }

        let participantIndex = indexPath.row - 1
        guard sectionParticipants.indices.contains(participantIndex) else {
            return UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GroupPreviewParticipantTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? GroupPreviewParticipantTableViewCell else {
            return UITableViewCell()
        }

        let participant = sectionParticipants[participantIndex]
        cell.configure(
            participant: participant,
            isActionEnabled: isPending(email: participant.email) == false
        ) { [weak self] in
            self?.handleParticipantAction(participant: participant, section: tableSection)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GroupPreviewViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let tableSection = TableSection(rawValue: indexPath.section) else {
            return UITableView.automaticDimension
        }
        if tableSection == .actions {
            return indexPath.row == 0 ? UIConstants.dividerRowHeight : UIConstants.inviteButtonRowHeight
        }

        if indexPath.row == 0 {
            return UIConstants.headerRowHeight
        }
        if isParticipantsLoading {
            return UIConstants.participantRowHeight
        }

        let sectionParticipants = participants(for: tableSection)
        if sectionParticipants.isEmpty {
            return UITableView.automaticDimension
        }

        return UIConstants.participantRowHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let tableSection = TableSection(rawValue: indexPath.section) else {
            return UITableView.automaticDimension
        }
        if tableSection == .actions {
            return indexPath.row == 0 ? UIConstants.dividerRowHeight : UIConstants.inviteButtonRowHeight
        }

        if indexPath.row == 0 {
            return UIConstants.headerRowHeight
        }
        if isParticipantsLoading {
            return UIConstants.participantRowHeight
        }

        let sectionParticipants = participants(for: tableSection)
        if sectionParticipants.isEmpty {
            return 34
        }

        return UIConstants.participantRowHeight
    }
}

// MARK: - AlertPresenting
extension GroupPreviewViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
    }
}

private extension GroupCreationBottomSheetViewController.EditGroupRequest.AvatarAction {
    func toPreviewAvatarAction() -> GroupPreviewModels.AvatarAction {
        switch self {
        case .unchanged:
            return .unchanged
        case .update(let data):
            return .update(data: data)
        case .remove:
            return .remove
        }
    }
}

private extension String {
    var normalizedEmail: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
