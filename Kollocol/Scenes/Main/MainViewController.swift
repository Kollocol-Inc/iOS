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

    // MARK: - Properties
    private var interactor: MainInteractor
    
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
        configureUI()
        configureNavbar()
        
        Task {
            await interactor.fetchUserProfile()
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

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
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

