//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import ShimmerView

final class ProfileViewController: UIViewController {
    // MARK: - Typealias
    private final class ProfileHeaderShimmerSyncView: UIView, ShimmerSyncTarget {
        // MARK: - Properties
        var style: ShimmerViewStyle = .default
        var effectBeginTime: CFTimeInterval = 0
    }

    // MARK: - UI Components
    private let profileInfoContainerView: ProfileHeaderShimmerSyncView = {
        let view = ProfileHeaderShimmerSyncView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 28
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 9
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let profileContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "avatarPlaceholder"))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22.5
        imageView.layer.borderWidth = 1.5
        imageView.clipsToBounds = true
        imageView.backgroundColor = .backgroundSecondary
        return imageView
    }()

    private let avatarShimmerView = ShimmerView()

    private let profileTextStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 0
        return stack
    }()

    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .textPrimary
        label.text = " "
        label.alpha = 0
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .textSecondary
        label.text = " "
        label.alpha = 0
        return label
    }()

    private let fullNameShimmerView = ShimmerView()
    private let emailShimmerView = ShimmerView()

    private let tableBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 28
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 9
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let profileInfoTopInset: CGFloat = 10
        static let profileInfoHorizontalInset: CGFloat = 24
        static let profileInfoHeight: CGFloat = 80
        static let profileInfoToTableSpacing: CGFloat = 16
        static let profileInfoInnerInset: CGFloat = 16
        static let avatarSize: CGFloat = 45
        static let fullNameShimmerWidth: CGFloat = 148
        static let fullNameShimmerHeight: CGFloat = 16
        static let emailShimmerWidth: CGFloat = 126
        static let emailShimmerHeight: CGFloat = 12
    }

    // MARK: - Properties
    private var interactor: ProfileInteractor
    private var isProfileShimmerAnimating = false

    private lazy var profileShimmerViews: [ShimmerView] = [
        avatarShimmerView,
        fullNameShimmerView,
        emailShimmerView
    ]

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

        Task {
            await interactor.fetchUserProfile()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        updateAvatarBorderColor(for: traitCollection)
        guard isProfileShimmerAnimating else { return }

        let shimmerStyle = makeProfileShimmerStyle(for: effectiveShimmerTraitCollection)
        profileInfoContainerView.style = shimmerStyle
        profileShimmerViews.forEach { $0.apply(style: shimmerStyle) }
    }

    // MARK: - Methods
    @MainActor
    func displayUserProfile(avatarUrl: String?, fullName: String, email: String) {
        stopProfileLoadingShimmer()

        fullNameLabel.text = fullName
        emailLabel.text = email
        avatarImageView.setImage(url: avatarUrl, placeholder: UIImage(named: "avatarPlaceholder"))
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureNavbar()
        configureProfileShimmerShape()
        updateAvatarBorderColor(for: traitCollection)
        startProfileLoadingShimmer()
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

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(
                    systemName: "door.right.hand.open"
                )?.withTintColor(
                    .backgroundRedPrimary,
                    renderingMode: .alwaysOriginal
                ),
                primaryAction: showPopupAndLogoutAction
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
        view.addSubview(profileInfoContainerView)
        profileInfoContainerView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.profileInfoTopInset)
        profileInfoContainerView.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, UIConstants.profileInfoHorizontalInset)
        profileInfoContainerView.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, UIConstants.profileInfoHorizontalInset)
        profileInfoContainerView.setHeight(UIConstants.profileInfoHeight)

        profileInfoContainerView.addSubview(profileContentStackView)
        profileContentStackView.pinLeft(to: profileInfoContainerView.leadingAnchor, UIConstants.profileInfoInnerInset)
        profileContentStackView.pinRight(to: profileInfoContainerView.trailingAnchor, UIConstants.profileInfoInnerInset, .lsOE)
        profileContentStackView.pinCenterY(to: profileInfoContainerView.centerYAnchor)

        profileContentStackView.addArrangedSubview(avatarImageView)
        avatarImageView.setWidth(UIConstants.avatarSize)
        avatarImageView.setHeight(UIConstants.avatarSize)

        profileContentStackView.addArrangedSubview(profileTextStackView)
        profileTextStackView.addArrangedSubview(fullNameLabel)
        profileTextStackView.addArrangedSubview(emailLabel)

        avatarImageView.addSubview(avatarShimmerView)
        avatarShimmerView.pin(to: avatarImageView)

        profileTextStackView.addSubview(fullNameShimmerView)
        fullNameShimmerView.pinLeft(to: profileTextStackView.leadingAnchor)
        fullNameShimmerView.pinCenterY(to: fullNameLabel.centerYAnchor)
        fullNameShimmerView.setWidth(UIConstants.fullNameShimmerWidth)
        fullNameShimmerView.setHeight(UIConstants.fullNameShimmerHeight)

        profileTextStackView.addSubview(emailShimmerView)
        emailShimmerView.pinLeft(to: profileTextStackView.leadingAnchor)
        emailShimmerView.pinCenterY(to: emailLabel.centerYAnchor)
        emailShimmerView.setWidth(UIConstants.emailShimmerWidth)
        emailShimmerView.setHeight(UIConstants.emailShimmerHeight)

        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinHorizontal(to: view)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)
        tableBackgroundView.pinTop(to: profileInfoContainerView.bottomAnchor, UIConstants.profileInfoToTableSpacing)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)

        profileInfoContainerView.bringSubviewToFront(view)
    }

    private func configureProfileShimmerShape() {
        avatarShimmerView.layer.cornerRadius = UIConstants.avatarSize / 2
        avatarShimmerView.layer.masksToBounds = true

        fullNameShimmerView.layer.cornerRadius = UIConstants.fullNameShimmerHeight / 2
        fullNameShimmerView.layer.masksToBounds = true

        emailShimmerView.layer.cornerRadius = UIConstants.emailShimmerHeight / 2
        emailShimmerView.layer.masksToBounds = true
    }

    private var effectiveShimmerTraitCollection: UITraitCollection {
        view.window?.traitCollection ?? traitCollection
    }

    private func startProfileLoadingShimmer() {
        isProfileShimmerAnimating = true
        let shimmerStyle = makeProfileShimmerStyle(for: effectiveShimmerTraitCollection)
        profileInfoContainerView.style = shimmerStyle
        profileInfoContainerView.effectBeginTime = CACurrentMediaTime()

        fullNameLabel.alpha = 0
        emailLabel.alpha = 0

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

        fullNameLabel.alpha = 1
        emailLabel.alpha = 1
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

    private func updateAvatarBorderColor(for traitCollection: UITraitCollection) {
        avatarImageView.layer.borderColor = UIColor.accentPrimary.resolvedColor(with: traitCollection).cgColor
    }
}
