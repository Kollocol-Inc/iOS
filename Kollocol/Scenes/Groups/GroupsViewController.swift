//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import ShimmerView

final class GroupsViewController: UIViewController {
    // MARK: - UI Components
    private let modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: [
            "groupsSegmentMember".localized,
            "groupsSegmentOwner".localized
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

    private let searchTextField: UITextField = {
        let field = UITextField()
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
        field.attributedPlaceholder = NSAttributedString(
            string: "groupsSearchPlaceholder".localized,
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

    private let contentContainerView = UIView()

    private let memberGroupsContainerView = UIView()

    private let ownerGroupsContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let memberGroupsTableBackgroundView: UIView = {
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

    private let ownerGroupsTableBackgroundView: UIView = {
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

    private let memberGroupsTableView: UITableView = {
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

    private let ownerGroupsTableView: UITableView = {
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
        static let navbarHorizontalInset: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
        static let pickerHeight: CGFloat = 36
        static let pickerTopInset: CGFloat = 12
        static let groupCellHeight: CGFloat = 82
        static let slideAnimationDuration: TimeInterval = 0.32
        static let shimmerRowsCount: Int = 7
    }

    // MARK: - Properties
    private var interactor: GroupsInteractor
    private var mode: GroupsModels.Mode = .member
    private var memberGroups: [GroupsModels.GroupViewData] = []
    private var ownerGroups: [GroupsModels.GroupViewData] = []
    private var memberEmptyStateText: String?
    private var ownerEmptyStateText: String?
    private var isGroupsLoading = false
    private var groupsShimmerEffectBeginTime: CFTimeInterval = 0

    // MARK: - Lifecycle
    init(interactor: GroupsInteractor) {
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        refreshLocalizedContent()

        Task {
            self.setGroupsLoading(true)
            await interactor.fetchGroups()
            self.setGroupsLoading(false)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard isGroupsLoading else { return }
        memberGroupsTableView.reloadData()
        ownerGroupsTableView.reloadData()
    }

    // MARK: - Methods
    @MainActor
    func displayGroups(
        memberGroups: [GroupsModels.GroupViewData],
        ownerGroups: [GroupsModels.GroupViewData],
        memberEmptyStateText: String?,
        ownerEmptyStateText: String?
    ) {
        self.memberGroups = memberGroups
        self.ownerGroups = ownerGroups
        self.memberEmptyStateText = memberEmptyStateText
        self.ownerEmptyStateText = ownerEmptyStateText
        setGroupsLoading(false)
        memberGroupsTableView.reloadData()
        ownerGroupsTableView.reloadData()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTables()
        configureActions()
        applyModeLayout(
            for: mode,
            from: nil,
            animated: false
        )
    }

    private func configureNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "groupsTitle".localized
        titleLabel.textColor = .textSecondary
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        navigationItem.titleView = titleLabel

        let plusConfiguration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 17, weight: .medium))
        let plusImage = UIImage(systemName: "plus", withConfiguration: plusConfiguration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: plusImage,
            primaryAction: UIAction { [weak self] _ in
                self?.handleCreateGroupTapped()
            }
        )
    }

    private func refreshLocalizedContent() {
        modeSegmentedControl.setTitle("groupsSegmentMember".localized, forSegmentAt: 0)
        modeSegmentedControl.setTitle("groupsSegmentOwner".localized, forSegmentAt: 1)
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "groupsSearchPlaceholder".localized,
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )

        if let titleLabel = navigationItem.titleView as? UILabel {
            titleLabel.text = "groupsTitle".localized
        }
    }

    private func configureConstraints() {
        view.addSubview(modeSegmentedControl)
        modeSegmentedControl.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.pickerTopInset)
        modeSegmentedControl.pinLeft(to: view.leadingAnchor, UIConstants.navbarHorizontalInset)
        modeSegmentedControl.pinRight(to: view.trailingAnchor, UIConstants.navbarHorizontalInset)
        modeSegmentedControl.setHeight(UIConstants.pickerHeight)

        view.addSubview(searchTextField)
        searchTextField.pinTop(to: modeSegmentedControl.bottomAnchor, UIConstants.sectionSpacing)
        searchTextField.pinLeft(to: view.leadingAnchor, UIConstants.navbarHorizontalInset)
        searchTextField.pinRight(to: view.trailingAnchor, UIConstants.navbarHorizontalInset)

        view.addSubview(contentContainerView)
        contentContainerView.pinTop(to: searchTextField.bottomAnchor, UIConstants.sectionSpacing)
        contentContainerView.pinLeft(to: view.leadingAnchor)
        contentContainerView.pinRight(to: view.trailingAnchor)
        contentContainerView.pinBottom(to: view.bottomAnchor)

        contentContainerView.addSubview(memberGroupsContainerView)
        memberGroupsContainerView.pin(to: contentContainerView)

        contentContainerView.addSubview(ownerGroupsContainerView)
        ownerGroupsContainerView.pin(to: contentContainerView)

        configureMemberGroupsLayout()
        configureOwnerGroupsLayout()
    }

    private func configureMemberGroupsLayout() {
        memberGroupsContainerView.addSubview(memberGroupsTableBackgroundView)
        memberGroupsTableBackgroundView.pinTop(to: memberGroupsContainerView.topAnchor)
        memberGroupsTableBackgroundView.pinLeft(to: memberGroupsContainerView.leadingAnchor)
        memberGroupsTableBackgroundView.pinRight(to: memberGroupsContainerView.trailingAnchor)
        memberGroupsTableBackgroundView.pinBottom(to: memberGroupsContainerView.bottomAnchor)

        memberGroupsContainerView.addSubview(memberGroupsTableView)
        memberGroupsTableView.pin(to: memberGroupsTableBackgroundView)
    }

    private func configureOwnerGroupsLayout() {
        ownerGroupsContainerView.addSubview(ownerGroupsTableBackgroundView)
        ownerGroupsTableBackgroundView.pinTop(to: ownerGroupsContainerView.topAnchor)
        ownerGroupsTableBackgroundView.pinLeft(to: ownerGroupsContainerView.leadingAnchor)
        ownerGroupsTableBackgroundView.pinRight(to: ownerGroupsContainerView.trailingAnchor)
        ownerGroupsTableBackgroundView.pinBottom(to: ownerGroupsContainerView.bottomAnchor)

        ownerGroupsContainerView.addSubview(ownerGroupsTableView)
        ownerGroupsTableView.pin(to: ownerGroupsTableBackgroundView)
    }

    private func configureTables() {
        memberGroupsTableView.register(GroupCardTableViewCell.self, forCellReuseIdentifier: GroupCardTableViewCell.reuseIdentifier)
        memberGroupsTableView.register(GroupCardShimmerTableViewCell.self, forCellReuseIdentifier: GroupCardShimmerTableViewCell.reuseIdentifier)
        memberGroupsTableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)
        memberGroupsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        memberGroupsTableView.dataSource = self
        memberGroupsTableView.delegate = self

        ownerGroupsTableView.register(GroupCardTableViewCell.self, forCellReuseIdentifier: GroupCardTableViewCell.reuseIdentifier)
        ownerGroupsTableView.register(GroupCardShimmerTableViewCell.self, forCellReuseIdentifier: GroupCardShimmerTableViewCell.reuseIdentifier)
        ownerGroupsTableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)
        ownerGroupsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 12, right: 0)
        ownerGroupsTableView.dataSource = self
        ownerGroupsTableView.delegate = self
    }

    private func configureActions() {
        modeSegmentedControl.addTarget(self, action: #selector(handlePickerValueChanged), for: .valueChanged)
        searchTextField.addTarget(self, action: #selector(handleSearchTextChanged), for: .editingChanged)
    }

    private func applyModeLayout(
        for mode: GroupsModels.Mode,
        from previousMode: GroupsModels.Mode?,
        animated: Bool
    ) {
        let visibleContainer = mode == .member ? memberGroupsContainerView : ownerGroupsContainerView
        let hiddenContainer = mode == .member ? ownerGroupsContainerView : memberGroupsContainerView

        guard animated else {
            visibleContainer.isHidden = false
            hiddenContainer.isHidden = true
            visibleContainer.alpha = 1
            hiddenContainer.alpha = 1
            visibleContainer.transform = .identity
            hiddenContainer.transform = .identity
            return
        }

        let slideDirection: CGFloat = {
            switch (previousMode, mode) {
            case (.member, .owner):
                return 1
            case (.owner, .member):
                return -1
            default:
                return 0
            }
        }()

        visibleContainer.isHidden = false
        hiddenContainer.isHidden = false

        let slideWidth = max(contentContainerView.bounds.width, view.bounds.width)
        visibleContainer.transform = CGAffineTransform(translationX: slideDirection * slideWidth, y: 0)
        hiddenContainer.transform = .identity

        UIView.animate(
            withDuration: UIConstants.slideAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 0.94,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut]
        ) {
            visibleContainer.transform = .identity
            hiddenContainer.transform = CGAffineTransform(translationX: -slideDirection * slideWidth, y: 0)
        } completion: { _ in
            hiddenContainer.isHidden = true
            hiddenContainer.transform = .identity
            visibleContainer.isHidden = false
            visibleContainer.transform = .identity
        }
    }

    private func switchMode(to newMode: GroupsModels.Mode, animated: Bool) {
        guard newMode != mode else { return }
        let previousMode = mode
        mode = newMode
        applyModeLayout(
            for: newMode,
            from: previousMode,
            animated: animated
        )
    }

    private func rowData(for tableView: UITableView) -> (items: [GroupsModels.GroupViewData], emptyText: String?) {
        if tableView === ownerGroupsTableView {
            return (ownerGroups, ownerEmptyStateText)
        }
        return (memberGroups, memberEmptyStateText)
    }

    private var effectiveShimmerTraitCollection: UITraitCollection {
        view.window?.traitCollection ?? traitCollection
    }

    private func setGroupsLoading(_ isLoading: Bool) {
        if isLoading {
            guard isGroupsLoading == false else { return }
            isGroupsLoading = true
            groupsShimmerEffectBeginTime = CACurrentMediaTime()
            memberGroupsTableView.reloadData()
            ownerGroupsTableView.reloadData()
            return
        }

        guard isGroupsLoading else { return }
        isGroupsLoading = false
        memberGroupsTableView.reloadData()
        ownerGroupsTableView.reloadData()
    }

    private func makeGroupsShimmerStyle() -> ShimmerViewStyle {
        let traitCollection = effectiveShimmerTraitCollection
        return ShimmerViewStyle(
            baseColor: UIColor.backgroundSecondary.resolvedColor(with: traitCollection),
            highlightColor: UIColor.backgroundPrimary.resolvedColor(with: traitCollection),
            duration: 1.2,
            interval: 0.4,
            effectSpan: .points(120),
            effectAngle: 0 * CGFloat.pi
        )
    }

    // MARK: - Actions
    @objc
    private func handlePickerValueChanged() {
        let newMode: GroupsModels.Mode = modeSegmentedControl.selectedSegmentIndex == 0 ? .member : .owner
        switchMode(to: newMode, animated: true)
    }

    @objc
    private func handleSearchTextChanged() {
        let query = searchTextField.text ?? ""
        interactor.handleSearchQueryChanged(query)
    }

    @objc
    private func handleCreateGroupTapped() {
        let viewController = GroupCreationBottomSheetViewController(mode: .create)
        viewController.onCreateGroup = { [weak self] groupName, description, memberEmails, avatarData in
            guard let self else { return false }
            return await self.interactor.createGroup(
                name: groupName,
                description: description,
                memberEmails: memberEmails,
                avatarData: avatarData
            )
        }

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
}

// MARK: - UITableViewDataSource
extension GroupsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isGroupsLoading {
            return UIConstants.shimmerRowsCount
        }

        let data = rowData(for: tableView)
        if data.items.isEmpty, data.emptyText != nil {
            return 1
        }

        return data.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isGroupsLoading {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupCardShimmerTableViewCell.reuseIdentifier, for: indexPath) as? GroupCardShimmerTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(
                shimmerStyle: makeGroupsShimmerStyle(),
                effectBeginTime: groupsShimmerEffectBeginTime
            )
            return cell
        }

        let data = rowData(for: tableView)

        if data.items.isEmpty, let emptyText = data.emptyText {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateTableViewCell.reuseIdentifier, for: indexPath) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: emptyText)
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: GroupCardTableViewCell.reuseIdentifier, for: indexPath) as? GroupCardTableViewCell else {
            return UITableViewCell()
        }

        guard data.items.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }

        cell.configure(with: data.items[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate
extension GroupsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isGroupsLoading {
            return UIConstants.groupCellHeight
        }

        let data = rowData(for: tableView)
        if data.items.isEmpty, data.emptyText != nil {
            return UITableView.automaticDimension
        }

        return UIConstants.groupCellHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if isGroupsLoading {
            return UIConstants.groupCellHeight
        }

        let data = rowData(for: tableView)
        if data.items.isEmpty, data.emptyText != nil {
            return 34
        }

        return UIConstants.groupCellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard isGroupsLoading == false else { return }
        defer { tableView.deselectRow(at: indexPath, animated: true) }

        let data = rowData(for: tableView)
        guard data.items.indices.contains(indexPath.row) else { return }
        let selectedGroup = data.items[indexPath.row]

        Task { [weak self] in
            guard let self else { return }
            await self.interactor.handleGroupTap(selectedGroup, mode: self.mode)
        }
    }
}
