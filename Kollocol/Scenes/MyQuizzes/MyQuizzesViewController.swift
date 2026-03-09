//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class MyQuizzesViewController: UIViewController {
    // MARK: - UI Components
    private let modeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Мои квизы", "Шаблоны"])
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

    private let contentContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let myQuizzesContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let templatesContainerView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()

    private let myQuizzesTableBackgroundView: UIView = {
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

    private let myQuizzesTableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.allowsSelection = false
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    private lazy var myQuizzesRefreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        return control
    }()

    private lazy var templatesRefreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handleTemplatesPullToRefresh), for: .valueChanged)
        return control
    }()

    private let templatesSearchTextField: UITextField = {
        let field = UITextField()
        field.attributedPlaceholder = NSAttributedString(
            string: "Поиск шаблонов",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 15, weight: .medium)
            ]
        )
        field.backgroundColor = .dividerPrimary
        field.textColor = .textSecondary
        field.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        field.layer.cornerRadius = 18
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

    private let createTemplateButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.setAttributedTitle(
            NSAttributedString(
                string: "Создать",
                attributes: [
                    .foregroundColor: UIColor.textWhite,
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
                ]
            ),
            for: .normal
        )
        button.setHeight(44)
        return button
    }()

    private let templatesTableBackgroundView: UIView = {
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

    private let templatesTableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.allowsSelection = false
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
    }

    // MARK: - Properties
    private var interactor: MyQuizzesInteractor
    private var mode: MyQuizzesModels.Mode = .myQuizzes
    private var rows: [MyQuizzesModels.Row] = []
    private var templateItems: [QuizInstanceViewData] = []
    private var templatesEmptyStateText: String?

    // MARK: - Lifecycle
    init(interactor: MyQuizzesInteractor) {
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

        Task {
            await interactor.fetchHostingQuizzes()
        }

        Task {
            await interactor.fetchTemplates()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Methods
    @MainActor
    func displayHostingQuizzes(_ items: [QuizInstanceViewData]) {
        rows = buildRows(from: items)
        myQuizzesTableView.reloadData()
        myQuizzesRefreshControl.endRefreshing()
    }

    @MainActor
    func displayTemplates(_ items: [QuizInstanceViewData], emptyStateText: String?) {
        templateItems = items
        templatesEmptyStateText = emptyStateText
        templatesTableView.reloadData()
        templatesRefreshControl.endRefreshing()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureTables()
        configureActions()
    }

    private func configureConstraints() {
        view.addSubview(modeSegmentedControl)
        modeSegmentedControl.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.pickerTopInset)
        modeSegmentedControl.pinLeft(to: view.leadingAnchor, UIConstants.navbarHorizontalInset)
        modeSegmentedControl.pinRight(to: view.trailingAnchor, UIConstants.navbarHorizontalInset)
        modeSegmentedControl.setHeight(UIConstants.pickerHeight)

        view.addSubview(contentContainerView)
        contentContainerView.pinTop(to: modeSegmentedControl.bottomAnchor, UIConstants.sectionSpacing)
        contentContainerView.pinLeft(to: view.leadingAnchor)
        contentContainerView.pinRight(to: view.trailingAnchor)
        contentContainerView.pinBottom(to: view.bottomAnchor)

        contentContainerView.addSubview(myQuizzesContainerView)
        myQuizzesContainerView.pin(to: contentContainerView)

        contentContainerView.addSubview(templatesContainerView)
        templatesContainerView.pin(to: contentContainerView)

        configureMyQuizzesLayout()
        configureTemplatesLayout()
    }

    private func configureMyQuizzesLayout() {
        myQuizzesContainerView.addSubview(myQuizzesTableBackgroundView)
        myQuizzesTableBackgroundView.pinTop(to: myQuizzesContainerView.topAnchor)
        myQuizzesTableBackgroundView.pinLeft(to: myQuizzesContainerView.leadingAnchor)
        myQuizzesTableBackgroundView.pinRight(to: myQuizzesContainerView.trailingAnchor)
        myQuizzesTableBackgroundView.pinBottom(to: myQuizzesContainerView.bottomAnchor)

        myQuizzesContainerView.addSubview(myQuizzesTableView)
        myQuizzesTableView.pin(to: myQuizzesTableBackgroundView)
    }

    private func configureTemplatesLayout() {
        templatesContainerView.addSubview(templatesSearchTextField)
        templatesSearchTextField.pinTop(to: templatesContainerView.topAnchor, 2)
        templatesSearchTextField.pinLeft(to: templatesContainerView.leadingAnchor, UIConstants.navbarHorizontalInset)
        templatesSearchTextField.pinRight(to: templatesContainerView.trailingAnchor, UIConstants.navbarHorizontalInset)

        templatesContainerView.addSubview(createTemplateButton)
        createTemplateButton.pinTop(to: templatesSearchTextField.bottomAnchor, UIConstants.sectionSpacing)
        createTemplateButton.pinLeft(to: templatesContainerView.leadingAnchor, UIConstants.navbarHorizontalInset)
        createTemplateButton.pinRight(to: templatesContainerView.trailingAnchor, UIConstants.navbarHorizontalInset)

        templatesContainerView.addSubview(templatesTableBackgroundView)
        templatesTableBackgroundView.pinTop(to: createTemplateButton.bottomAnchor, UIConstants.sectionSpacing)
        templatesTableBackgroundView.pinLeft(to: templatesContainerView.leadingAnchor)
        templatesTableBackgroundView.pinRight(to: templatesContainerView.trailingAnchor)
        templatesTableBackgroundView.pinBottom(to: templatesContainerView.bottomAnchor)

        templatesContainerView.addSubview(templatesTableView)
        templatesTableView.pin(to: templatesTableBackgroundView)
    }

    private func configureTables() {
        myQuizzesTableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        myQuizzesTableView.register(CardsTableViewCell.self, forCellReuseIdentifier: CardsTableViewCell.reuseIdentifier)
        myQuizzesTableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        myQuizzesTableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)
        myQuizzesTableView.refreshControl = myQuizzesRefreshControl
        myQuizzesTableView.dataSource = self
        myQuizzesTableView.delegate = self

        templatesTableView.register(QuizCardTableViewCell.self, forCellReuseIdentifier: QuizCardTableViewCell.reuseIdentifier)
        templatesTableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)
        templatesTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        templatesTableView.refreshControl = templatesRefreshControl
        templatesTableView.dataSource = self
        templatesTableView.delegate = self
    }

    private func configureActions() {
        modeSegmentedControl.addTarget(self, action: #selector(handlePickerValueChanged), for: .valueChanged)
        createTemplateButton.addTarget(self, action: #selector(handleCreateTemplateButtonTapped), for: .touchUpInside)
        templatesSearchTextField.addTarget(self, action: #selector(handleTemplateSearchTextChanged), for: .editingChanged)
    }

    private func buildRows(from items: [QuizInstanceViewData]) -> [MyQuizzesModels.Row] {
        let activeItems = items.filter { $0.status == .active }
        let pendingReviewItems = items.filter { $0.status == .pendingReview }
        let reviewedItems = items.filter { $0.status == .reviewed }

        return [
            .header(title: "Провожу"),
            activeItems.isEmpty
            ? .empty(text: "Нет квизов, которые вы проводите")
            : .cards(items: activeItems),
            .divider,
            .header(title: "Ожидают оценивания"),
            pendingReviewItems.isEmpty
            ? .empty(text: "Нет квизов, ожидающих оценки")
            : .cards(items: pendingReviewItems),
            .divider,
            .header(title: "Оценены"),
            reviewedItems.isEmpty
            ? .empty(text: "Нет квизов, которые вы оценили")
            : .cards(items: reviewedItems)
        ]
    }

    private func switchMode(to newMode: MyQuizzesModels.Mode, animated: Bool) {
        guard newMode != mode else { return }

        let fromView: UIView
        let toView: UIView
        let direction: CGFloat

        switch (mode, newMode) {
        case (.myQuizzes, .templates):
            fromView = myQuizzesContainerView
            toView = templatesContainerView
            direction = 1
        case (.templates, .myQuizzes):
            fromView = templatesContainerView
            toView = myQuizzesContainerView
            direction = -1
        default:
            return
        }

        mode = newMode

        guard animated else {
            fromView.isHidden = true
            toView.isHidden = false
            return
        }

        let width = contentContainerView.bounds.width
        toView.isHidden = false
        toView.transform = CGAffineTransform(translationX: direction * width, y: 0)
        fromView.transform = .identity

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut]) {
            fromView.transform = CGAffineTransform(translationX: -direction * width, y: 0)
            toView.transform = .identity
        } completion: { _ in
            fromView.transform = .identity
            fromView.isHidden = true
        }
    }

    // MARK: - Actions
    @objc
    private func handlePickerValueChanged() {
        let newMode: MyQuizzesModels.Mode = modeSegmentedControl.selectedSegmentIndex == 0 ? .myQuizzes : .templates
        switchMode(to: newMode, animated: true)
    }

    @objc
    private func handlePullToRefresh() {
        Task {
            await interactor.fetchHostingQuizzes()
        }
    }

    @objc
    private func handleCreateTemplateButtonTapped() {
        Task {
            await interactor.routeToCreateTemplateScreen()
        }
    }

    @objc
    private func handleTemplateSearchTextChanged() {
        interactor.handleTemplateSearchQueryChanged(templatesSearchTextField.text ?? "")
    }

    @objc
    private func handleTemplatesPullToRefresh() {
        templatesSearchTextField.text = nil
        interactor.handleTemplateSearchQueryChanged("")

        Task {
            await interactor.fetchTemplates()
        }
    }
}

// MARK: - UITableViewDataSource
extension MyQuizzesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView === templatesTableView {
            if templateItems.isEmpty, templatesEmptyStateText != nil {
                return 1
            }

            return templateItems.count
        }

        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === templatesTableView {
            if templateItems.isEmpty, let emptyText = templatesEmptyStateText {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateTableViewCell.reuseIdentifier, for: indexPath) as? EmptyStateTableViewCell else {
                    return UITableViewCell()
                }

                cell.configure(text: emptyText)
                return cell
            }

            guard let cell = tableView.dequeueReusableCell(withIdentifier: QuizCardTableViewCell.reuseIdentifier, for: indexPath) as? QuizCardTableViewCell else {
                return UITableViewCell()
            }

            guard templateItems.indices.contains(indexPath.row) else {
                return UITableViewCell()
            }

            let item = templateItems[indexPath.row]
            cell.configure(with: item, isTemplate: true)
            cell.onQuizStartTap = { [weak self] in
                Task { [weak self] in
                    await self?.interactor.routeToStartQuizScreen(templateId: item.id)
                }
            }

            return cell
        }

        guard tableView === myQuizzesTableView else { return UITableViewCell() }

        switch rows[indexPath.row] {
        case .header(let title):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HeaderTableViewCell.reuseIdentifier, for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: title)
            return cell

        case .cards(let items):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardsTableViewCell.reuseIdentifier, for: indexPath) as? CardsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: items)
            cell.onQuizStartTap = { [weak self] item in
                Task { [weak self] in
                    await self?.interactor.routeToStartQuizScreen(templateId: item.id)
                }
            }
            return cell

        case .empty(let text):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: EmptyStateTableViewCell.reuseIdentifier, for: indexPath) as? EmptyStateTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text)
            return cell

        case .divider:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DividerTableViewCell.reuseIdentifier, for: indexPath) as? DividerTableViewCell else {
                return UITableViewCell()
            }

            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension MyQuizzesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView === templatesTableView {
            return templateItems.isEmpty ? UITableView.automaticDimension : 150
        }

        guard tableView === myQuizzesTableView else { return 0 }

        switch rows[indexPath.row] {
        case .header: return 46
        case .cards: return 178
        case .empty: return UITableView.automaticDimension
        case .divider: return 1
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView === templatesTableView {
            return templateItems.isEmpty ? 34 : 150
        }

        guard tableView === myQuizzesTableView else { return 0 }

        switch rows[indexPath.row] {
        case .empty: return 34
        default: return 44
        }
    }
}
