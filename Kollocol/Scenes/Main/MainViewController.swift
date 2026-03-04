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
            await interactor.fetchParticipatingQuizzes()
        }

        Task {
            await interactor.fetchHostingQuizzes()
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
    func displayParticipatingQuizzes(_ quizInstances: [QuizInstanceViewData]) {
        self.quizParticipatingInstances = quizInstances
        self.tableView.reloadData()
    }

    @MainActor
    func displayHostingQuizzes(_ quizInstances: [QuizInstanceViewData]) {
        self.quizHostingInstances = quizInstances
        self.tableView.reloadData()
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
        tableView.register(DividerTableViewCell.self, forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
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
}


// MARK: - UITableViewDataSource
extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HeaderTableViewCell.reuseIdentifier, for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: "Участвую")

            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardsTableViewCell.reuseIdentifier, for: indexPath) as? CardsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: quizParticipatingInstances)

            return cell

        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: DividerTableViewCell.reuseIdentifier, for: indexPath) as? DividerTableViewCell else {
                return UITableViewCell()
            }

            return cell

        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HeaderTableViewCell.reuseIdentifier, for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: "Провожу")

            return cell

        case 4:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardsTableViewCell.reuseIdentifier, for: indexPath) as? CardsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: quizHostingInstances)

            return cell

        default:
            return UITableViewCell()
        }
    }
}

// MARK: - UITableViewDelegate
extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0: return 46  // header height
        case 1: return 178 // card height + 8 spacing + pager
        case 2: return 1 // divider height
        case 3: return 46 // header height
        case 4: return 178 // card height + 8 spacing + pager
        default: return 0
        }
    }
}
