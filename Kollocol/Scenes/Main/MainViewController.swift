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
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.allowsSelection = false
        table.keyboardDismissMode = .onDrag
        table.sectionHeaderTopPadding = 0
        return table
    }()

    // MARK: - Properties
    private var interactor: MainInteractor
    private var currentCode: String?
    private var isJoinLoading = false
    private var quizInstances: [QuizInstanceViewData] = []

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
        self.quizInstances = quizInstances
        self.tableView.reloadData()
    }

    @MainActor
    func resetCodeFields() {
        isJoinLoading = false
        currentCode = nil
        
        if let codeCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CodeInputTableViewCell {
            codeCell.resetFields()
        }
        
        if let buttonCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ButtonTableViewCell {
            buttonCell.setLoading(false)
            buttonCell.setEnabled(false)
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureTableView()
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.pin(to: view)
        
        tableView.register(CodeInputTableViewCell.self, forCellReuseIdentifier: CodeInputTableViewCell.reuseIdentifier)
        tableView.register(ButtonTableViewCell.self, forCellReuseIdentifier: ButtonTableViewCell.reuseIdentifier)
        tableView.register(HeaderTableViewCell.self, forCellReuseIdentifier: HeaderTableViewCell.reuseIdentifier)
        tableView.register(CardsTableViewCell.self, forCellReuseIdentifier: CardsTableViewCell.reuseIdentifier)
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CodeInputTableViewCell.reuseIdentifier, for: indexPath) as? CodeInputTableViewCell else {
                return UITableViewCell()
            }

            cell.onCodeChanged = { [weak self] code in
                self?.currentCode = code
                if let buttonCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? ButtonTableViewCell {
                    buttonCell.setEnabled(code?.count == 6)
                }
            }

            if isJoinLoading {
                cell.startAnimating()
            } else {
                cell.stopAnimating()
            }

            return cell

        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: ButtonTableViewCell.reuseIdentifier, for: indexPath) as? ButtonTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: "Погнали!") { [weak self] in
                guard let self, let code = self.currentCode else { return }

                self.isJoinLoading = true

                if let codeCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? CodeInputTableViewCell {
                    codeCell.startAnimating()
                }

                cell.setLoading(true)

                Task {
                    await self.interactor.joinQuiz(code: code)
                }
            }

            cell.setEnabled(currentCode?.count == 6)
            cell.setLoading(isJoinLoading)

            return cell

        case 2:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: HeaderTableViewCell.reuseIdentifier, for: indexPath) as? HeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(title: "Участвую")

            return cell

        case 3:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardsTableViewCell.reuseIdentifier, for: indexPath) as? CardsTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(with: quizInstances)

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
        case 0: return 94 // 70 height + 16 top + 8 bottom
        case 1: return 66 // 42 height + 8 top + 16 bottom
        case 2: return 46 // header height
        case 3: return 178 // card height + 8 spacing + pager
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == 3 {
            cell.layer.zPosition = 1
        } else {
            cell.layer.zPosition = 0
        }
    }
}
