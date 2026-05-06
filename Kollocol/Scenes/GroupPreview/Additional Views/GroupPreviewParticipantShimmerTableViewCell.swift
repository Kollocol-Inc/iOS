//
//  GroupPreviewParticipantShimmerTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import UIKit
import ShimmerView

final class GroupPreviewParticipantShimmerTableViewCell: UITableViewCell {
    // MARK: - Typealias
    private final class ShimmerSyncContainerView: UIView, ShimmerSyncTarget {
        // MARK: - Properties
        var style: ShimmerViewStyle = .default
        var effectBeginTime: CFTimeInterval = 0
    }

    // MARK: - UI Components
    private let shimmerSyncContainerView: ShimmerSyncContainerView = {
        let view = ShimmerSyncContainerView()
        view.backgroundColor = .clear
        return view
    }()

    private let avatarShimmerView = ShimmerView()
    private let fullNameShimmerView = ShimmerView()
    private let emailShimmerView = ShimmerView()

    // MARK: - Constants
    static let reuseIdentifier = "GroupPreviewParticipantShimmerTableViewCell"

    private enum UIConstants {
        static let avatarLeftInset: CGFloat = 28
        static let avatarSize: CGFloat = 44
        static let avatarBottomInset: CGFloat = 10

        static let textLeftInsetFromAvatar: CGFloat = 12
        static let textRightInset: CGFloat = 24
        static let fullNameTopInset: CGFloat = 8
        static let fullNameHeight: CGFloat = 14
        static let emailTopInset: CGFloat = 6
        static let emailHeight: CGFloat = 12
    }

    // MARK: - Properties
    private lazy var shimmerViews: [ShimmerView] = [
        avatarShimmerView,
        fullNameShimmerView,
        emailShimmerView
    ]

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopAnimating()
    }

    // MARK: - Methods
    func configure(
        shimmerStyle: ShimmerViewStyle,
        effectBeginTime: CFTimeInterval
    ) {
        shimmerSyncContainerView.style = shimmerStyle
        shimmerSyncContainerView.effectBeginTime = effectBeginTime

        shimmerViews.forEach {
            $0.style = shimmerStyle
            $0.apply(style: shimmerStyle)
            $0.startAnimating()
        }
    }

    // MARK: - Private Methods
    private func configureUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(shimmerSyncContainerView)
        shimmerSyncContainerView.pin(to: contentView)

        shimmerSyncContainerView.addSubview(avatarShimmerView)
        avatarShimmerView.pinLeft(to: shimmerSyncContainerView.leadingAnchor, UIConstants.avatarLeftInset)
        avatarShimmerView.pinTop(to: shimmerSyncContainerView.topAnchor)
        avatarShimmerView.pinBottom(to: shimmerSyncContainerView.bottomAnchor, UIConstants.avatarBottomInset)
        avatarShimmerView.setWidth(UIConstants.avatarSize)
        avatarShimmerView.setHeight(UIConstants.avatarSize)

        shimmerSyncContainerView.addSubview(fullNameShimmerView)
        fullNameShimmerView.pinLeft(to: avatarShimmerView.trailingAnchor, UIConstants.textLeftInsetFromAvatar)
        fullNameShimmerView.pinTop(to: shimmerSyncContainerView.topAnchor, UIConstants.fullNameTopInset)
        fullNameShimmerView.pinRight(to: shimmerSyncContainerView.trailingAnchor, UIConstants.textRightInset, .lsOE)
        fullNameShimmerView.pinWidth(to: shimmerSyncContainerView.widthAnchor, 0.5)
        fullNameShimmerView.setHeight(UIConstants.fullNameHeight)

        shimmerSyncContainerView.addSubview(emailShimmerView)
        emailShimmerView.pinLeft(to: avatarShimmerView.trailingAnchor, UIConstants.textLeftInsetFromAvatar)
        emailShimmerView.pinTop(to: fullNameShimmerView.bottomAnchor, UIConstants.emailTopInset)
        emailShimmerView.pinRight(to: shimmerSyncContainerView.trailingAnchor, UIConstants.textRightInset, .lsOE)
        emailShimmerView.pinWidth(to: shimmerSyncContainerView.widthAnchor, 0.34)
        emailShimmerView.setHeight(UIConstants.emailHeight)

        configureShimmerShape()
    }

    private func configureShimmerShape() {
        avatarShimmerView.layer.cornerRadius = UIConstants.avatarSize / 2
        avatarShimmerView.layer.masksToBounds = true

        fullNameShimmerView.layer.cornerRadius = UIConstants.fullNameHeight / 2
        fullNameShimmerView.layer.masksToBounds = true

        emailShimmerView.layer.cornerRadius = UIConstants.emailHeight / 2
        emailShimmerView.layer.masksToBounds = true
    }

    private func stopAnimating() {
        shimmerViews.forEach { $0.stopAnimating() }
    }
}
