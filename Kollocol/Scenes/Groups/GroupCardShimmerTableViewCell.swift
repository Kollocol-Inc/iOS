//
//  GroupCardShimmerTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 07.05.2026.
//

import UIKit
import ShimmerView

final class GroupCardShimmerTableViewCell: UITableViewCell {
    // MARK: - Typealias
    private final class ShimmerSyncContainerView: UIView, ShimmerSyncTarget {
        // MARK: - Properties
        var style: ShimmerViewStyle = .default
        var effectBeginTime: CFTimeInterval = 0
    }

    // MARK: - UI Components
    private let groupCardView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundCardPrimary
        view.layer.cornerRadius = 18
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 20
        view.layer.shadowOpacity = 0.2
        view.clipsToBounds = false
        return view
    }()

    private let shimmerSyncContainerView: ShimmerSyncContainerView = {
        let view = ShimmerSyncContainerView()
        view.backgroundColor = .clear
        return view
    }()

    private let avatarShimmerView = ShimmerView()
    private let titleShimmerView = ShimmerView()
    private let subtitleShimmerView = ShimmerView()

    // MARK: - Constants
    static let reuseIdentifier = "GroupCardShimmerTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let topInset: CGFloat = 12
        static let cardHeight: CGFloat = 70

        static let avatarLeftInset: CGFloat = 16
        static let avatarSize: CGFloat = 45
        static let textLeftInsetFromAvatar: CGFloat = 8
        static let textRightInset: CGFloat = 16

        static let titleHeight: CGFloat = 14
        static let subtitleHeight: CGFloat = 12
        static let titleTopInset: CGFloat = 18
        static let subtitleTopInset: CGFloat = 8
    }

    // MARK: - Properties
    private lazy var shimmerViews: [ShimmerView] = [
        avatarShimmerView,
        titleShimmerView,
        subtitleShimmerView
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

        contentView.addSubview(groupCardView)
        groupCardView.pinTop(to: contentView.topAnchor, UIConstants.topInset)
        groupCardView.pinLeft(to: contentView.leadingAnchor, UIConstants.horizontalInset)
        groupCardView.pinRight(to: contentView.trailingAnchor, UIConstants.horizontalInset)
        groupCardView.pinBottom(to: contentView.bottomAnchor)
        groupCardView.setHeight(UIConstants.cardHeight)

        groupCardView.addSubview(shimmerSyncContainerView)
        shimmerSyncContainerView.pin(to: groupCardView)

        shimmerSyncContainerView.addSubview(avatarShimmerView)
        avatarShimmerView.pinLeft(to: shimmerSyncContainerView.leadingAnchor, UIConstants.avatarLeftInset)
        avatarShimmerView.pinCenterY(to: shimmerSyncContainerView.centerYAnchor)
        avatarShimmerView.setWidth(UIConstants.avatarSize)
        avatarShimmerView.setHeight(UIConstants.avatarSize)

        shimmerSyncContainerView.addSubview(titleShimmerView)
        titleShimmerView.pinLeft(to: avatarShimmerView.trailingAnchor, UIConstants.textLeftInsetFromAvatar)
        titleShimmerView.pinTop(to: shimmerSyncContainerView.topAnchor, UIConstants.titleTopInset)
        titleShimmerView.pinRight(to: shimmerSyncContainerView.trailingAnchor, UIConstants.textRightInset, .lsOE)
        titleShimmerView.pinWidth(to: shimmerSyncContainerView.widthAnchor, 0.58)
        titleShimmerView.setHeight(UIConstants.titleHeight)

        shimmerSyncContainerView.addSubview(subtitleShimmerView)
        subtitleShimmerView.pinLeft(to: avatarShimmerView.trailingAnchor, UIConstants.textLeftInsetFromAvatar)
        subtitleShimmerView.pinTop(to: titleShimmerView.bottomAnchor, UIConstants.subtitleTopInset)
        subtitleShimmerView.pinRight(to: shimmerSyncContainerView.trailingAnchor, UIConstants.textRightInset, .lsOE)
        subtitleShimmerView.pinWidth(to: shimmerSyncContainerView.widthAnchor, 0.42)
        subtitleShimmerView.setHeight(UIConstants.subtitleHeight)

        configureShimmerShape()
    }

    private func configureShimmerShape() {
        avatarShimmerView.layer.cornerRadius = UIConstants.avatarSize / 2
        avatarShimmerView.layer.masksToBounds = true

        titleShimmerView.layer.cornerRadius = UIConstants.titleHeight / 2
        titleShimmerView.layer.masksToBounds = true

        subtitleShimmerView.layer.cornerRadius = UIConstants.subtitleHeight / 2
        subtitleShimmerView.layer.masksToBounds = true
    }

    private func stopAnimating() {
        shimmerViews.forEach { $0.stopAnimating() }
    }
}
