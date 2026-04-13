//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import ShimmerView

final class MainViewController: UIViewController {
    // MARK: - Typealias
    private final class ProfileShimmerSyncView: UIView, ShimmerSyncTarget {
        // MARK: - Properties
        var style: ShimmerViewStyle = .default
        var effectBeginTime: CFTimeInterval = 0
    }

    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.clipsToBounds = true
        imageView.backgroundColor = .backgroundSecondary
        return imageView
    }()

    private let avatarShimmerView = ShimmerView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .textPrimary
        label.isHidden = true
        return label
    }()
    
    private let nameShimmerView = ShimmerView()

    private let leftBarButtonCustomView: ProfileShimmerSyncView = {
        let view = ProfileShimmerSyncView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    private let codeInputView: CodeInputTableViewCell = {
        let cell = CodeInputTableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }()

    private let joinButtonView: ButtonTableViewCell = {
        let cell = ButtonTableViewCell(style: .default, reuseIdentifier: nil)
        return cell
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.allowsSelection = false
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        table.backgroundColor = .clear
        return table
    }()

    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        return control
    }()

    private let tableViewBackgroundView: UIView = {
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

    // MARK: - Properties
    private var interactor: MainInteractor
    private var currentCode: String?
    private var isJoinLoading = false
    private var quizParticipatingInstances: [QuizInstanceViewData] = []
    private var quizHostingInstances: [QuizInstanceViewData] = []
    private var rows: [MainModels.Row] = []
    private var isProfileShimmerAnimating = false

    private lazy var profileShimmerViews: [ShimmerView] = [
        avatarShimmerView,
        nameShimmerView
    ]

    // MARK: - Lifecycle
    init(interactor: MainInteractor) {
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
        configureNavbar()
        
        Task {
            await interactor.fetchUserProfile()
        }

        initialState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Task {
            async let userProfileTask: Void = interactor.fetchUserProfile()
            async let quizzesTask: Void = interactor.fetchQuizzes()
            _ = await (userProfileTask, quizzesTask)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard isProfileShimmerAnimating else { return }

        let shimmerStyle = makeProfileShimmerStyle(for: traitCollection)
        leftBarButtonCustomView.style = shimmerStyle
        profileShimmerViews.forEach { $0.apply(style: shimmerStyle) }
    }

    // MARK: - Methods
    @MainActor
    func displayUserProfile(avatarUrl: String?, name: String) {
        stopProfileLoadingShimmer()
        nameLabel.isHidden = false
        
        nameLabel.text = name
        avatarImageView.setImage(url: avatarUrl, placeholder: UIImage(named: "avatarPlaceholder"))
    }

    @MainActor
    func displayQuizzes(participating: [QuizInstanceViewData], hosting: [QuizInstanceViewData]) {
        quizParticipatingInstances = participating
        quizHostingInstances = hosting
        rows = buildRows(participating: quizParticipatingInstances, hosting: quizHostingInstances)
        tableView.reloadData()
    }

    @MainActor
    func resetCodeFields() {
        isJoinLoading = false
        currentCode = nil
        
        codeInputView.resetFields()
        joinButtonView.setLoading(false)
        joinButtonView.setEnabled(false)
    }

    @MainActor
    func confirmJoinQuiz(accessCode: String, skipAsyncConfirmation: Bool) {
        Task {
            await interactor.joinQuiz(
                code: accessCode,
                skipAsyncConfirmation: skipAsyncConfirmation
            )
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureActions()
        configureTableView()
    }

    private func initialState() {
        joinButtonView.setEnabled(currentCode?.count == 6)
        joinButtonView.setLoading(isJoinLoading)
        if isJoinLoading {
            codeInputView.startAnimating()
        } else {
            codeInputView.stopAnimating()
        }
    }

    private func configureConstraints() {
        view.addSubview(codeInputView)
        codeInputView.pinLeft(to: view.leadingAnchor)
        codeInputView.pinRight(to: view.trailingAnchor)
        codeInputView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        codeInputView.setHeight(94)

        view.addSubview(joinButtonView)
        joinButtonView.pinLeft(to: view.leadingAnchor)
        joinButtonView.pinRight(to: view.trailingAnchor)
        joinButtonView.pinTop(to: codeInputView.bottomAnchor)
        joinButtonView.setHeight(66)

        view.addSubview(tableViewBackgroundView)
        tableViewBackgroundView.pinLeft(to: view.leadingAnchor)
        tableViewBackgroundView.pinRight(to: view.trailingAnchor)
        tableViewBackgroundView.pinTop(to: joinButtonView.bottomAnchor)
        tableViewBackgroundView.pinBottom(to: view.bottomAnchor)

        view.addSubview(tableView)
        tableView.pin(to: tableViewBackgroundView)
    }

    private func configureActions() {
        codeInputView.onCodeChanged = { [weak self] code in
            self?.currentCode = code
            self?.joinButtonView.setEnabled(code?.count == 6)
        }

        joinButtonView.configure(title: "Погнали!") { [weak self] in
            guard let self, let code = self.currentCode else { return }

            self.isJoinLoading = true

            self.codeInputView.startAnimating()
            self.joinButtonView.setLoading(true)

            Task {
                await self.interactor.joinQuiz(code: code, skipAsyncConfirmation: false)
            }
        }
    }

    private func configureTableView() {
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(CardsTableViewCell.self, forCellReuseIdentifier: CardsTableViewCell.reuseIdentifier)
        tableView.register(EmptyStateTableViewCell.self, forCellReuseIdentifier: EmptyStateTableViewCell.reuseIdentifier)
        tableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
    }

    private func reloadMainContent() async {
        async let userProfileTask: Void = interactor.fetchUserProfile()
        async let quizzesTask: Void = interactor.fetchQuizzes()

        _ = await (userProfileTask, quizzesTask)
        await MainActor.run {
            refreshControl.endRefreshing()
        }
    }

    private func buildRows(
        participating: [QuizInstanceViewData],
        hosting: [QuizInstanceViewData]
    ) -> [MainModels.Row] {
        [
            .header(title: "Участвую"),
            participating.isEmpty
            ? .empty(text: "Нет квизов, в которых вы участвуете")
            : .cards(items: participating),
            .divider,
            .header(title: "Провожу"),
            hosting.isEmpty
            ? .empty(text: "Нет квизов, которые вы проводите")
            : .cards(items: hosting)
        ]
    }

    private func configureNavbar() {
        // title
        navigationItem.title = nil
        navigationItem.titleView = nil

        // left button
        configureLeftBarButton()

        // right button
        let redirectToNotificationsScreenAction = UIAction { [weak self] _ in
            Task { [weak self] in
                // TODO: route to notifications screen
            }
        }

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(
                    systemName: "bell.fill"
                )?.withTintColor(
                    .accentPrimary,
                    renderingMode: .alwaysOriginal
                ),
                primaryAction: redirectToNotificationsScreenAction
            )
        ]
    }

    private func configureLeftBarButton() {
        leftBarButtonCustomView.addSubview(avatarImageView)
        leftBarButtonCustomView.addSubview(nameLabel)
        leftBarButtonCustomView.addSubview(nameShimmerView)

        avatarImageView.pinLeft(to: leftBarButtonCustomView)
        avatarImageView.pinCenterY(to: leftBarButtonCustomView)
        avatarImageView.setWidth(44)
        avatarImageView.setHeight(44)

        avatarImageView.addSubview(avatarShimmerView)
        avatarShimmerView.pin(to: avatarImageView)

        nameLabel.pinLeft(to: avatarImageView.trailingAnchor, 8)
        nameLabel.pinRight(to: leftBarButtonCustomView)
        nameLabel.pinCenterY(to: avatarImageView)
        
        nameShimmerView.pinLeft(to: avatarImageView.trailingAnchor, 8)
        nameShimmerView.pinCenterY(to: avatarImageView)
        nameShimmerView.setWidth(140)
        nameShimmerView.setHeight(20)
        nameShimmerView.pinRight(to: leftBarButtonCustomView, 0, .lsOE)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(leftBarButtonTapped))
        leftBarButtonCustomView.addGestureRecognizer(tapGesture)

        let leftItem = UIBarButtonItem(customView: leftBarButtonCustomView)
        leftItem.hidesSharedBackground = true
        navigationItem.leftBarButtonItem = leftItem

        configureProfileShimmerShape()
        startProfileLoadingShimmer()
    }

    private func configureProfileShimmerShape() {
        avatarShimmerView.layer.cornerRadius = 22
        avatarShimmerView.layer.masksToBounds = true

        nameShimmerView.layer.cornerRadius = 10
        nameShimmerView.layer.masksToBounds = true
    }

    private func startProfileLoadingShimmer() {
        isProfileShimmerAnimating = true
        let shimmerStyle = makeProfileShimmerStyle(for: traitCollection)
        leftBarButtonCustomView.style = shimmerStyle
        leftBarButtonCustomView.effectBeginTime = CACurrentMediaTime()

        profileShimmerViews.forEach {
            $0.isHidden = false
            $0.apply(style: shimmerStyle)
            $0.startAnimating()
        }
    }

    private func stopProfileLoadingShimmer() {
        isProfileShimmerAnimating = false

        profileShimmerViews.forEach {
            $0.stopAnimating()
            $0.isHidden = true
        }
    }

    private func makeProfileShimmerStyle(for traitCollection: UITraitCollection) -> ShimmerViewStyle {
        ShimmerViewStyle(
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
    private func leftBarButtonTapped() {
        Task {
            await interactor.routeToProfileScreen()
        }
    }

    @objc
    private func handlePullToRefresh() {
        Task {
            await reloadMainContent()
        }
    }
}


// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            cell.onQuizTypeTap = { [weak self] quizType in
                Task { [weak self] in
                    await self?.interactor.handleQuizTypeTap(quizType)
                }
            }
            cell.onQuizTap = { [weak self] quiz in
                Task { [weak self] in
                    await self?.interactor.handleQuizCardTap(quiz)
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
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .header: return 46
        case .cards: return 178
        case .empty: return UITableView.automaticDimension
        case .divider: return 1
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .empty: return 34
        default: return 44
        }
    }
}
