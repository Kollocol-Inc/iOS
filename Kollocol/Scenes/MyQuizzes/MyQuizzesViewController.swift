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

    private let searchTextField: UITextField = {
        let field = UITextField()
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

    private let searchPlaceholderContainerView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private let searchPlaceholderPrefixLabel: UILabel = {
        let label = UILabel()
        label.text = "Поиск"
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let searchPlaceholderSuffixContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        return view
    }()

    private let searchPlaceholderCurrentSuffixLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()

    private let searchPlaceholderIncomingSuffixLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.alpha = 0
        return label
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
        static let createButtonHeight: CGFloat = 44
        static let searchPlaceholderAnimationDuration: TimeInterval = 0.5
        static let searchPlaceholderSuffixSpacing: CGFloat = 4
        static let deleteTemplateAlertTitle = "Удаление шаблона"
        static let deleteTemplateAlertMessage = "Вы уверены, что хотите удалить шаблон %@? Это действие необратимо"
    }

    // MARK: - Properties
    private var interactor: MyQuizzesInteractor
    private var mode: MyQuizzesModels.Mode = .myQuizzes
    private var rows: [MyQuizzesModels.Row] = []
    private var templateItems: [QuizInstanceViewData] = []
    private var templatesEmptyStateText: String?
    private var searchQuery = ""
    private var shouldRefreshTemplatesOnAppear = false
    private var templateGenerationTask: Task<Void, Never>?

    private var contentContainerTopConstraint: NSLayoutConstraint?
    private var searchPlaceholderSuffixWidthConstraint: NSLayoutConstraint?
    private var currentSearchPlaceholderSuffix = "квизов"
    private var isSearchPlaceholderAnimating = false

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)

        if shouldRefreshTemplatesOnAppear {
            shouldRefreshTemplatesOnAppear = false
        }

        Task {
            async let hostingTask: Void = interactor.fetchHostingQuizzes()
            async let templatesTask: Void = interactor.fetchTemplates()
            _ = await (hostingTask, templatesTask)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    deinit {
        templateGenerationTask?.cancel()
    }

    // MARK: - Methods
    @MainActor
    func displayHostingQuizzes(_ items: [QuizInstanceViewData]) {
        rows = buildRows(from: items)
        reloadTable(myQuizzesTableView)
        myQuizzesRefreshControl.endRefreshing()
    }

    @MainActor
    func displayTemplates(_ items: [QuizInstanceViewData], emptyStateText: String?) {
        templateItems = items
        templatesEmptyStateText = emptyStateText
        reloadTable(templatesTableView)
        templatesRefreshControl.endRefreshing()
    }

    @MainActor
    func scheduleTemplatesRefreshOnAppear() {
        shouldRefreshTemplatesOnAppear = true
    }

    @MainActor
    func confirmJoinQuiz(accessCode: String) {
        Task {
            await interactor.joinQuiz(code: accessCode)
        }
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
            animated: false,
            shouldPropagateSearchQuery: false
        )
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
        configureSearchPlaceholder()

        view.addSubview(createTemplateButton)
        createTemplateButton.pinTop(to: searchTextField.bottomAnchor, UIConstants.sectionSpacing)
        createTemplateButton.pinLeft(to: view.leadingAnchor, UIConstants.navbarHorizontalInset)
        createTemplateButton.pinRight(to: view.trailingAnchor, UIConstants.navbarHorizontalInset)
        createTemplateButton.setHeight(UIConstants.createButtonHeight)

        view.addSubview(contentContainerView)
        contentContainerTopConstraint = contentContainerView.pinTop(
            to: searchTextField.bottomAnchor,
            UIConstants.sectionSpacing
        )
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
        templatesContainerView.addSubview(templatesTableBackgroundView)
        templatesTableBackgroundView.pinTop(to: templatesContainerView.topAnchor)
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
        templatesTableView.allowsSelection = true
        templatesTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        templatesTableView.refreshControl = templatesRefreshControl
        templatesTableView.dataSource = self
        templatesTableView.delegate = self
    }

    private func configureActions() {
        modeSegmentedControl.addTarget(self, action: #selector(handlePickerValueChanged), for: .valueChanged)
        configureCreateTemplateMenu()
        searchTextField.addTarget(self, action: #selector(handleSearchTextChanged), for: .editingChanged)
    }

    private func configureCreateTemplateMenu() {
        let createFromScratchAction = UIAction(
            title: "С нуля",
            image: UIImage(systemName: "pencil.and.ruler.fill")
        ) { [weak self] _ in
            self?.handleCreateTemplateFromScratchTapped()
        }

        let createWithAIAction = UIAction(
            title: "При помощи ИИ",
            image: UIImage(systemName: "wand.and.sparkles")
        ) { [weak self] _ in
            self?.handleCreateTemplateWithAITapped()
        }

        createTemplateButton.menu = UIMenu(
            options: .displayInline,
            children: [
                createFromScratchAction,
                createWithAIAction
            ]
        )
        createTemplateButton.showsMenuAsPrimaryAction = true
    }

    private func configureSearchPlaceholder() {
        searchTextField.attributedPlaceholder = nil

        searchTextField.addSubview(searchPlaceholderContainerView)
        searchPlaceholderContainerView.pinLeft(to: searchTextField.leadingAnchor, 35)
        searchPlaceholderContainerView.pinCenterY(to: searchTextField.centerYAnchor)
        searchPlaceholderContainerView.pinRight(to: searchTextField.trailingAnchor, 12, .lsOE)
        searchPlaceholderContainerView.setHeight(20)

        searchPlaceholderContainerView.addSubview(searchPlaceholderPrefixLabel)
        searchPlaceholderPrefixLabel.pinTop(to: searchPlaceholderContainerView.topAnchor)
        searchPlaceholderPrefixLabel.pinBottom(to: searchPlaceholderContainerView.bottomAnchor)
        searchPlaceholderPrefixLabel.pinLeft(to: searchPlaceholderContainerView.leadingAnchor)

        searchPlaceholderContainerView.addSubview(searchPlaceholderSuffixContainerView)
        searchPlaceholderSuffixContainerView.pinLeft(
            to: searchPlaceholderPrefixLabel.trailingAnchor,
            UIConstants.searchPlaceholderSuffixSpacing
        )
        searchPlaceholderSuffixContainerView.pinTop(to: searchPlaceholderContainerView.topAnchor)
        searchPlaceholderSuffixContainerView.pinBottom(to: searchPlaceholderContainerView.bottomAnchor)
        searchPlaceholderSuffixContainerView.pinRight(
            to: searchPlaceholderContainerView.trailingAnchor,
            0,
            .lsOE
        )

        searchPlaceholderSuffixContainerView.addSubview(searchPlaceholderCurrentSuffixLabel)
        searchPlaceholderCurrentSuffixLabel.pinLeft(to: searchPlaceholderSuffixContainerView.leadingAnchor)
        searchPlaceholderCurrentSuffixLabel.pinTop(to: searchPlaceholderSuffixContainerView.topAnchor)
        searchPlaceholderCurrentSuffixLabel.pinBottom(to: searchPlaceholderSuffixContainerView.bottomAnchor)

        searchPlaceholderSuffixContainerView.addSubview(searchPlaceholderIncomingSuffixLabel)
        searchPlaceholderIncomingSuffixLabel.pinLeft(to: searchPlaceholderSuffixContainerView.leadingAnchor)
        searchPlaceholderIncomingSuffixLabel.pinTop(to: searchPlaceholderSuffixContainerView.topAnchor)
        searchPlaceholderIncomingSuffixLabel.pinBottom(to: searchPlaceholderSuffixContainerView.bottomAnchor)

        searchPlaceholderCurrentSuffixLabel.text = currentSearchPlaceholderSuffix
        let initialSuffixWidth = widthForSearchPlaceholderSuffix(currentSearchPlaceholderSuffix)
        searchPlaceholderSuffixWidthConstraint = searchPlaceholderSuffixContainerView.setWidth(initialSuffixWidth)
        searchPlaceholderIncomingSuffixLabel.transform = CGAffineTransform(
            translationX: 0,
            y: searchPlaceholderCurrentSuffixLabel.font.lineHeight
        )

        updateSearchPlaceholderVisibility()
    }

    private func searchPlaceholderSuffix(for mode: MyQuizzesModels.Mode) -> String {
        mode == .templates ? "шаблонов" : "квизов"
    }

    private func widthForSearchPlaceholderSuffix(_ text: String) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .medium)
        ]
        return ceil((text as NSString).size(withAttributes: attributes).width) + 2
    }

    private func updateSearchPlaceholderVisibility() {
        let isEmpty = (searchTextField.text ?? "").isEmpty
        searchPlaceholderContainerView.isHidden = isEmpty == false
    }

    private func updateSearchPlaceholderSuffix(
        for mode: MyQuizzesModels.Mode,
        animated: Bool
    ) {
        let newSuffix = searchPlaceholderSuffix(for: mode)
        guard currentSearchPlaceholderSuffix != newSuffix else { return }

        let applyImmediately = {
            self.currentSearchPlaceholderSuffix = newSuffix
            self.searchPlaceholderCurrentSuffixLabel.text = newSuffix
            self.searchPlaceholderIncomingSuffixLabel.text = nil
            self.searchPlaceholderIncomingSuffixLabel.alpha = 0
            self.searchPlaceholderCurrentSuffixLabel.alpha = 1
            self.searchPlaceholderCurrentSuffixLabel.transform = .identity
            self.searchPlaceholderIncomingSuffixLabel.transform = CGAffineTransform(
                translationX: 0,
                y: self.searchPlaceholderCurrentSuffixLabel.font.lineHeight
            )
            self.searchPlaceholderSuffixWidthConstraint?.constant = self.widthForSearchPlaceholderSuffix(newSuffix)
        }

        guard animated, searchQuery.isEmpty, view.window != nil, isSearchPlaceholderAnimating == false else {
            applyImmediately()
            return
        }

        isSearchPlaceholderAnimating = true

        let lineHeight = searchPlaceholderCurrentSuffixLabel.font.lineHeight
        let targetWidth = max(
            widthForSearchPlaceholderSuffix(currentSearchPlaceholderSuffix),
            widthForSearchPlaceholderSuffix(newSuffix)
        )
        searchPlaceholderSuffixWidthConstraint?.constant = targetWidth
        searchPlaceholderIncomingSuffixLabel.text = newSuffix
        searchPlaceholderIncomingSuffixLabel.alpha = 1
        searchPlaceholderIncomingSuffixLabel.transform = CGAffineTransform(translationX: 0, y: lineHeight)
        searchPlaceholderCurrentSuffixLabel.transform = .identity
        searchPlaceholderCurrentSuffixLabel.alpha = 1

        UIView.animate(
            withDuration: UIConstants.searchPlaceholderAnimationDuration,
            delay: 0,
            options: [.curveEaseInOut]
        ) {
            self.searchPlaceholderCurrentSuffixLabel.transform = CGAffineTransform(translationX: 0, y: -lineHeight)
            self.searchPlaceholderCurrentSuffixLabel.alpha = 0
            self.searchPlaceholderIncomingSuffixLabel.transform = .identity
            self.view.layoutIfNeeded()
        } completion: { _ in
            applyImmediately()
            self.isSearchPlaceholderAnimating = false
            self.updateSearchPlaceholderVisibility()
        }
    }

    private func applyModeLayout(
        for mode: MyQuizzesModels.Mode,
        from previousMode: MyQuizzesModels.Mode?,
        animated: Bool,
        shouldPropagateSearchQuery: Bool
    ) {
        let isTemplatesMode = mode == .templates
        let visibleContainer = isTemplatesMode ? templatesContainerView : myQuizzesContainerView
        let hiddenContainer = isTemplatesMode ? myQuizzesContainerView : templatesContainerView
        let targetTopConstant = isTemplatesMode
        ? (UIConstants.sectionSpacing * 2 + UIConstants.createButtonHeight)
        : UIConstants.sectionSpacing

        searchTextField.text = searchQuery
        updateSearchPlaceholderVisibility()
        updateSearchPlaceholderSuffix(for: mode, animated: animated)

        if shouldPropagateSearchQuery {
            interactor.handleHostingSearchQueryChanged(searchQuery)
            interactor.handleTemplateSearchQueryChanged(searchQuery)
        }

        guard animated else {
            visibleContainer.isHidden = false
            hiddenContainer.isHidden = true
            visibleContainer.alpha = 1
            hiddenContainer.alpha = 1
            visibleContainer.transform = .identity
            hiddenContainer.transform = .identity
            contentContainerTopConstraint?.constant = targetTopConstant
            createTemplateButton.isUserInteractionEnabled = isTemplatesMode
            view.layoutIfNeeded()
            return
        }

        let slideDirection: CGFloat = {
            switch (previousMode, mode) {
            case (.myQuizzes, .templates):
                return 1
            case (.templates, .myQuizzes):
                return -1
            default:
                return 0
            }
        }()

        visibleContainer.isHidden = false
        hiddenContainer.isHidden = false

        let slideWidth = max(contentContainerView.bounds.width, view.bounds.width)
        visibleContainer.transform = CGAffineTransform(
            translationX: slideDirection * slideWidth,
            y: 0
        )
        hiddenContainer.transform = .identity
        createTemplateButton.isUserInteractionEnabled = false

        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.94,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut]
        ) {
            self.contentContainerTopConstraint?.constant = targetTopConstant
            visibleContainer.transform = .identity
            hiddenContainer.transform = CGAffineTransform(
                translationX: -slideDirection * slideWidth,
                y: 0
            )
            self.view.layoutIfNeeded()
        } completion: { _ in
            hiddenContainer.isHidden = true
            hiddenContainer.transform = .identity
            visibleContainer.isHidden = false
            visibleContainer.transform = .identity
            self.createTemplateButton.isUserInteractionEnabled = isTemplatesMode
        }
    }

    private func reloadTable(
        _ tableView: UITableView,
        rowAnimation: UITableView.RowAnimation = .fade
    ) {
        guard tableView.window != nil else {
            tableView.reloadData()
            return
        }

        let sectionsCount = tableView.numberOfSections
        guard sectionsCount > 0 else {
            tableView.reloadData()
            return
        }

        tableView.reloadSections(
            IndexSet(integersIn: 0..<sectionsCount),
            with: rowAnimation
        )
    }

    private func buildRows(from items: [QuizInstanceViewData]) -> [MyQuizzesModels.Row] {
        let activeItems = items.filter { $0.status == .active }
        let pendingReviewItems = items.filter { $0.status == .pendingReview }
        let reviewedItems = items.filter { item in
            item.status == .reviewed || item.status == .publishedResults
        }

        return [
            .header(title: "Провожу"),
            activeItems.isEmpty
            ? .empty(text: "Нет квизов, которые вы проводите")
            : .cards(items: activeItems, section: .active),
            .divider,
            .header(title: "Ожидают оценивания"),
            pendingReviewItems.isEmpty
            ? .empty(text: "Нет квизов, ожидающих оценки")
            : .cards(items: pendingReviewItems, section: .pendingReview),
            .divider,
            .header(title: "Оценены"),
            reviewedItems.isEmpty
            ? .empty(text: "Нет квизов, которые вы оценили")
            : .cards(items: reviewedItems, section: .reviewed)
        ]
    }

    private func templateItem(at indexPath: IndexPath) -> QuizInstanceViewData? {
        guard templateItems.indices.contains(indexPath.row) else { return nil }
        return templateItems[indexPath.row]
    }

    private func makeTemplateDeleteMessage(templateTitle: String?) -> String {
        let normalizedTitle = templateTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let displayTitle = normalizedTitle.isEmpty ? "без названия" : "«\(normalizedTitle)»"
        return String(format: UIConstants.deleteTemplateAlertMessage, displayTitle)
    }

    private func handleTemplateStartTap(_ item: QuizInstanceViewData) {
        Task { [weak self] in
            await self?.interactor.routeToStartQuizScreen(templateId: item.id)
        }
    }

    private func handleTemplateEditTap(_ item: QuizInstanceViewData) {
        guard let templateId = item.id else { return }

        Task { [weak self] in
            await self?.interactor.handleTemplateTap(templateId: templateId)
        }
    }

    private func handleTemplateDeleteTap(_ item: QuizInstanceViewData) {
        guard let templateId = item.id else { return }

        let message = makeTemplateDeleteMessage(templateTitle: item.title)
        showConfirmationAlert(
            title: UIConstants.deleteTemplateAlertTitle,
            message: message,
            cancelTitle: "Отмена",
            confirmTitle: "Удалить",
            confirmStyle: .destructive
        ) { [weak self] in
            Task { [weak self] in
                await self?.interactor.deleteTemplate(templateId: templateId)
            }
        }
    }

    private func switchMode(to newMode: MyQuizzesModels.Mode, animated: Bool) {
        guard newMode != mode else { return }
        let previousMode = mode
        mode = newMode
        applyModeLayout(
            for: newMode,
            from: previousMode,
            animated: animated,
            shouldPropagateSearchQuery: true
        )
    }

    private func startTemplateGeneration(
        prompt: String,
        in inputViewController: InputBottomSheetViewController
    ) {
        templateGenerationTask?.cancel()
        inputViewController.startGenerating()

        templateGenerationTask = Task { [weak self, weak inputViewController] in
            guard let self else { return }

            do {
                let generatedTemplate = try await interactor.generateTemplate(prompt: prompt)
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    guard let inputViewController else { return }

                    inputViewController.dismiss(animated: true) { [weak self] in
                        guard let self else { return }

                        Task { [weak self] in
                            await self?.interactor.routeToCreateTemplateScreen(from: generatedTemplate)
                        }
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    inputViewController?.stopGenerating()
                }

                let serviceError = error as? MLServiceError ?? .unknown
                await interactor.handleTemplateGenerationError(serviceError)
            }

            await MainActor.run {
                self.templateGenerationTask = nil
            }
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

    private func handleCreateTemplateFromScratchTapped() {
        Task {
            await interactor.routeToCreateTemplateScreen()
        }
    }

    private func handleCreateTemplateWithAITapped() {
        let inputViewController = InputBottomSheetViewController(
            content: InputBottomSheetContent(
                title: "Создание шаблона",
                placeholder: "Опишите, какой шаблон вы хотите создать",
                buttonTitle: "Сгенерировать"
            )
        )

        inputViewController.onGenerate = { [weak self, weak inputViewController] prompt in
            guard let self, let inputViewController else { return }
            self.startTemplateGeneration(prompt: prompt, in: inputViewController)
        }

        inputViewController.onExitWhileGenerating = { [weak self] in
            self?.templateGenerationTask?.cancel()
            self?.templateGenerationTask = nil
        }

        inputViewController.modalPresentationStyle = .pageSheet
        inputViewController.loadViewIfNeeded()

        if let sheet = inputViewController.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let fitDetent = UISheetPresentationController.Detent.custom(
                    identifier: .init("input.bottom.sheet.fit")
                ) { [weak inputViewController] context in
                    guard let inputViewController else {
                        return context.maximumDetentValue * 0.5
                    }

                    let preferredHeight = inputViewController.preferredContentSize.height
                    if preferredHeight > 0 {
                        return min(preferredHeight, context.maximumDetentValue)
                    }

                    return inputViewController.preferredSheetHeight(
                        maximumDetentValue: context.maximumDetentValue
                    )
                }

                sheet.detents = [fitDetent]
            } else {
                sheet.detents = [.medium()]
            }

            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }

        present(inputViewController, animated: true)
    }

    @objc
    private func handleSearchTextChanged() {
        let query = searchTextField.text ?? ""
        searchQuery = query
        updateSearchPlaceholderVisibility()
        interactor.handleHostingSearchQueryChanged(query)
        interactor.handleTemplateSearchQueryChanged(query)
    }

    @objc
    private func handleTemplatesPullToRefresh() {
        interactor.handleTemplateSearchQueryChanged(searchQuery)

        Task {
            await interactor.fetchTemplates()
        }
    }
}

// MARK: - AlertPresenting
extension MyQuizzesViewController: AlertPresenting {
    func presentAlert(_ alert: UIAlertController) {
        present(alert, animated: true)
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
            cell.onQuizTypeTap = { [weak self] quizType in
                Task { [weak self] in
                    await self?.interactor.handleQuizTypeTap(quizType)
                }
            }
            cell.onQuizStartTap = { [weak self] in
                self?.handleTemplateStartTap(item)
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

        case .cards(let items, let section):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardsTableViewCell.reuseIdentifier, for: indexPath) as? CardsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: items)
            cell.onQuizTypeTap = { [weak self] quizType in
                Task { [weak self] in
                    await self?.interactor.handleQuizTypeTap(quizType)
                }
            }
            cell.onQuizStartTap = { [weak self] item in
                Task { [weak self] in
                    await self?.interactor.routeToStartQuizScreen(templateId: item.id)
                }
            }
            cell.onQuizTap = { [weak self] item in
                Task { [weak self] in
                    await self?.interactor.handleHostingQuizTap(item, section: section)
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView === templatesTableView else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        guard let item = templateItem(at: indexPath) else { return }
        handleTemplateEditTap(item)
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard tableView === templatesTableView else { return nil }
        guard let item = templateItem(at: indexPath), item.id != nil else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self else { return UIMenu() }

            let startAction = UIAction(
                title: "Запустить",
                image: UIImage(systemName: "play.fill")
            ) { _ in
                self.handleTemplateStartTap(item)
            }

            let editAction = UIAction(
                title: "Изменить",
                image: UIImage(systemName: "pencil")
            ) { _ in
                self.handleTemplateEditTap(item)
            }

            let deleteAction = UIAction(
                title: "Удалить",
                image: UIImage(systemName: "trash.fill"),
                attributes: .destructive
            ) { _ in
                self.handleTemplateDeleteTap(item)
            }

            return UIMenu(children: [startAction, editAction, deleteAction])
        }
    }
}
