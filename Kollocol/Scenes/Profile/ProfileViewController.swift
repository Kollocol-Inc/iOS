//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class ProfileViewController: UIViewController {
    // MARK: - UI Components
    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .backgroundSecondary
        table.layer.masksToBounds = false
        table.layer.shadowColor = UIColor.black.cgColor
        table.layer.shadowRadius = 20
        table.layer.shadowOpacity = 0.2
        table.layer.cornerRadius = 30
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return table
    }()

    // MARK: - Properties
    private var interactor: ProfileInteractor

    // MARK: - Lifecycle
    init(interactor: ProfileInteractor) {
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
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureNavbar()
    }

    private func configureNavbar() {
        // title
        var title = AttributedString("Профиль")
        title.foregroundColor = .textSecondary
        title.font = .systemFont(ofSize: 20, weight: .bold)
        navigationItem.attributedTitle = title

        // right button
        let showPopupAndLogoutAction = UIAction { [weak self] _ in
            Task { [weak self] in
                await self?.interactor.logout()
            }
        }

        let changeNameAction = UIAction { [weak self] _ in
            Task { [weak self] in
                // await self?.interactor.changeName()
            }
        }

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(
                    systemName: "door.right.hand.open"
                )?.withTintColor(
                    .backgroundRedPrimary,
                    renderingMode: .alwaysOriginal
                ),
                primaryAction: showPopupAndLogoutAction
            ),
            UIBarButtonItem(
                image: UIImage(
                    systemName: "gearshape.fill"
                )?.withTintColor(
                    .textSecondary,
                    renderingMode: .alwaysOriginal
                ),
                primaryAction: changeNameAction
            )
        ]

        // left button
        navigationItem.backBarButtonItem = UIBarButtonItem(
            image: UIImage(
                systemName: "chevron.backward"
            )?.withTintColor(
                .textSecondary,
                renderingMode: .alwaysOriginal
            )
        )
    }

    private func configureConstraints() {
        view.addSubview(tableView)
        tableView.pinHorizontal(to: view)
        tableView.pinBottom(to: view.bottomAnchor)
        tableView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 10)
    }
}
