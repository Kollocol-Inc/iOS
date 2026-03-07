//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import SkeletonView

final class MainViewController: UIViewController {
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.clipsToBounds = true
        imageView.isSkeletonable = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .bold)
        label.textColor = .textPrimary
        label.isHidden = true
        return label
    }()
    
    private let nameSkeletonView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.isSkeletonable = true
        view.clipsToBounds = true
        return view
    }()

    private let leftBarButtonCustomView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isSkeletonable = true
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
        
        Task {
            await interactor.fetchQuizzes()
        }

        initialState()
    }

    // MARK: - Methods
    @MainActor
    func displayUserProfile(avatarUrl: String?, name: String) {
        avatarImageView.hideSkeleton()
        nameSkeletonView.hideSkeleton()
        nameSkeletonView.isHidden = true
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
                await self.interactor.joinQuiz(code: code)
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
        leftBarButtonCustomView.addSubview(nameSkeletonView)

        avatarImageView.pinLeft(to: leftBarButtonCustomView)
        avatarImageView.pinCenterY(to: leftBarButtonCustomView)
        avatarImageView.setWidth(44)
        avatarImageView.setHeight(44)

        nameLabel.pinLeft(to: avatarImageView.trailingAnchor, 8)
        nameLabel.pinRight(to: leftBarButtonCustomView)
        nameLabel.pinCenterY(to: avatarImageView)
        
        nameSkeletonView.pinLeft(to: avatarImageView.trailingAnchor, 8)
        nameSkeletonView.pinCenterY(to: avatarImageView)
        nameSkeletonView.setWidth(140)
        nameSkeletonView.setHeight(20)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(leftBarButtonTapped))
        leftBarButtonCustomView.addGestureRecognizer(tapGesture)

        let leftItem = UIBarButtonItem(customView: leftBarButtonCustomView)
        leftItem.hidesSharedBackground = true
        navigationItem.leftBarButtonItem = leftItem

        avatarImageView.showAnimatedGradientSkeleton()
        nameSkeletonView.showAnimatedGradientSkeleton()
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
