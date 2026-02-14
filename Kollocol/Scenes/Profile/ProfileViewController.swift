//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class ProfileViewController: UIViewController {
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(
                systemName: "door.right.hand.open"
            )?.withTintColor(
                .backgroundRedPrimary,
                renderingMode: .alwaysOriginal
            ),
            primaryAction: showPopupAndLogoutAction
        )
    }
}
