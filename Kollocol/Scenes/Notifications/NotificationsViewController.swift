//
//  NotificationsViewController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import UIKit

final class NotificationsViewController: UIViewController {
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
        label.textColor = .textSecondary
        label.textAlignment = .center
        return label
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let tableTopInset: CGFloat = 8
        static let notificationsTopInset: CGFloat = 10
        static let notificationsBottomInset: CGFloat = 12
        static let backButtonSize: CGFloat = 17
        static let dividerHeight: CGFloat = 1
        static let emptyStateEstimatedHeight: CGFloat = 34
    }

    // MARK: - Properties
    private let interactor: NotificationsInteractor

    private var notifications: [NotificationsModels.NotificationViewData] = []
    private var rows: [NotificationsModels.Row] = []

    private var previousNavigationBarTintColor: UIColor?
    private var previousBackIndicatorImage: UIImage?
    private var previousBackIndicatorTransitionMaskImage: UIImage?

    // MARK: - Lifecycle
    init(interactor: NotificationsInteractor) {
        self.interactor = interactor
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

        Task {
            await interactor.handleViewDidLoad()
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

    // MARK: - Methods
    @MainActor
    func displayNotifications(_ notifications: [NotificationsModels.NotificationViewData]) {
        self.notifications = notifications
        rebuildRows()
        tableView.reloadData()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTableView()
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
            NotificationTableViewCell.self,
            forCellReuseIdentifier: NotificationTableViewCell.reuseIdentifier
        )
        tableView.register(
            EmptyStateTableViewCell.self,
            forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier
        )
        tableView.register(
            DividerTableViewCell.self,
            forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier
        )

        tableView.contentInset = UIEdgeInsets(
            top: UIConstants.notificationsTopInset,
            left: 0,
            bottom: UIConstants.notificationsBottomInset,
            right: 0
        )

        tableView.dataSource = self
        tableView.delegate = self
    }

    private func configureNavigationBar() {
        navigationTitleLabel.text = "notificationsHeader".localized
        navigationItem.titleView = navigationTitleLabel
        navigationItem.hidesBackButton = false
        navigationItem.backButtonDisplayMode = .minimal
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
            font: .systemFont(ofSize: UIConstants.backButtonSize, weight: .semibold)
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

    private func rebuildRows() {
        guard notifications.isEmpty == false else {
            rows = [.empty("notificationsNoNotifications".localized)]
            return
        }

        var value: [NotificationsModels.Row] = []

        notifications.enumerated().forEach { index, notification in
            value.append(.notification(notification))
            if index < notifications.count - 1 {
                value.append(.divider)
            }
        }

        rows = value
    }
}

// MARK: - UITableViewDataSource
extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .notification(let notification):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: NotificationTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? NotificationTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                with: notification,
                onIgnoreTap: { [weak self] in
                    Task {
                        await self?.interactor.handleInviteAction(
                            notificationId: notification.id,
                            action: .ignore
                        )
                    }
                },
                onAcceptTap: { [weak self] in
                    Task {
                        await self?.interactor.handleInviteAction(
                            notificationId: notification.id,
                            action: .accept
                        )
                    }
                }
            )
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

        case .divider:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: DividerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? DividerTableViewCell else {
                return UITableViewCell()
            }

            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .notification:
            return UITableView.automaticDimension

        case .empty:
            return UITableView.automaticDimension

        case .divider:
            return UIConstants.dividerHeight
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .notification:
            return 96

        case .empty:
            return UIConstants.emptyStateEstimatedHeight

        case .divider:
            return UIConstants.dividerHeight
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case .notification(let notification) = rows[indexPath.row] else { return }

        Task {
            await interactor.handleNotificationWillDisplay(notificationId: notification.id)
        }
    }
}
