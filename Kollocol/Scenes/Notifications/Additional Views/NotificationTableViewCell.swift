//
//  NotificationTableViewCell.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import UIKit

final class NotificationTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let topContentView = UIView()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        return imageView
    }()

    private let flameGradientIconView = FlameGradientIconView()

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let titleRowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let unreadDotView: UIView = {
        let view = UIView()
        view.backgroundColor = .accentPrimary
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let titleDateSpacerView = UIView()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .textSecondary
        label.numberOfLines = 0
        return label
    }()

    private let inviteActionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let ignoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .buttonSecondary
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return button
    }()

    private let acceptButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.clipsToBounds = true
        button.setTitleColor(.textWhite, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        return button
    }()

    // MARK: - Constants
    static let reuseIdentifier = "NotificationTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let verticalInset: CGFloat = 12
        static let iconSize: CGFloat = 24
        static let iconTextSpacing: CGFloat = 14
        static let unreadDotSize: CGFloat = 6
        static let actionButtonHeight: CGFloat = 42
        static let inviteActionsDefaultSpacing: CGFloat = 8
        static let inviteActionsTransitionDuration: TimeInterval = 0.25
        static let mainStackDefaultSpacing: CGFloat = 8
    }

    // MARK: - Properties
    private var onIgnoreTap: (() -> Void)?
    private var onAcceptTap: (() -> Void)?
    private var inviteActionsHeightConstraint: NSLayoutConstraint?
    private var ignoreEqualWidthConstraint: NSLayoutConstraint?
    private var ignoreCollapsedWidthConstraint: NSLayoutConstraint?
    private var inviteActionState: NotificationsModels.InviteActionState = .ignored

    // MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        flameGradientIconView.applyCurrentColors(using: traitCollection)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onIgnoreTap = nil
        onAcceptTap = nil
        resetInviteActionsLayout()
    }

    // MARK: - Methods
    func configure(
        with notification: NotificationsModels.NotificationViewData,
        onIgnoreTap: (() -> Void)?,
        onAcceptTap: (() -> Void)?
    ) {
        self.onIgnoreTap = onIgnoreTap
        self.onAcceptTap = onAcceptTap

        titleLabel.text = notification.title
        descriptionLabel.text = notification.description
        dateLabel.text = notification.dateText

        unreadDotView.isHidden = notification.isRead

        configureIcon(type: notification.type)
        configureInviteActions(with: notification)
    }

    // MARK: - Private Methods
    private func configureUI() {
        configureBackground()
        configureHierarchy()
        configureConstraints()
        configureActions()
        resetInviteActionsLayout()
    }

    private func configureBackground() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        inviteActionsStackView.clipsToBounds = true
    }

    private func configureHierarchy() {
        contentView.addSubview(mainStackView)

        mainStackView.addArrangedSubview(topContentView)
        mainStackView.addArrangedSubview(inviteActionsStackView)

        topContentView.addSubview(iconImageView)
        topContentView.addSubview(flameGradientIconView)
        topContentView.addSubview(textStackView)

        textStackView.addArrangedSubview(titleRowStackView)
        textStackView.addArrangedSubview(descriptionLabel)

        titleRowStackView.addArrangedSubview(unreadDotView)
        titleRowStackView.addArrangedSubview(titleLabel)
        titleRowStackView.addArrangedSubview(titleDateSpacerView)
        titleRowStackView.addArrangedSubview(dateLabel)

        inviteActionsStackView.addArrangedSubview(ignoreButton)
        inviteActionsStackView.addArrangedSubview(acceptButton)

        ignoreButton.setTitle("notificationsIgnoreButton".localized, for: .normal)
        acceptButton.setTitle("notificationsAcceptButton".localized, for: .normal)
    }

    private func configureConstraints() {
        mainStackView.pinTop(to: contentView.topAnchor, UIConstants.verticalInset)
        mainStackView.pinBottom(to: contentView.bottomAnchor, UIConstants.verticalInset)
        mainStackView.pinLeft(to: contentView.safeAreaLayoutGuide.leadingAnchor, UIConstants.horizontalInset)
        mainStackView.pinRight(to: contentView.safeAreaLayoutGuide.trailingAnchor, UIConstants.horizontalInset)

        iconImageView.pinLeft(to: topContentView.leadingAnchor)
        iconImageView.setWidth(UIConstants.iconSize)
        iconImageView.setHeight(UIConstants.iconSize)
        iconImageView.pinTop(to: topContentView.topAnchor, 0, .grOE)
        iconImageView.pinBottom(to: topContentView.bottomAnchor, 0, .lsOE)

        flameGradientIconView.pinLeft(to: topContentView.leadingAnchor)
        flameGradientIconView.setWidth(UIConstants.iconSize)
        flameGradientIconView.setHeight(UIConstants.iconSize)
        flameGradientIconView.pinTop(to: topContentView.topAnchor, 0, .grOE)
        flameGradientIconView.pinBottom(to: topContentView.bottomAnchor, 0, .lsOE)

        textStackView.pinTop(to: topContentView.topAnchor)
        textStackView.pinBottom(to: topContentView.bottomAnchor)
        textStackView.pinLeft(to: iconImageView.trailingAnchor, UIConstants.iconTextSpacing)
        textStackView.pinRight(to: topContentView.trailingAnchor)

        iconImageView.centerYAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -2).isActive = true
        flameGradientIconView.centerYAnchor.constraint(equalTo: descriptionLabel.topAnchor, constant: -2).isActive = true

        unreadDotView.setWidth(UIConstants.unreadDotSize)
        unreadDotView.setHeight(UIConstants.unreadDotSize)

        inviteActionsHeightConstraint = inviteActionsStackView.setHeight(UIConstants.actionButtonHeight)
        ignoreEqualWidthConstraint = ignoreButton.pinWidth(to: acceptButton.widthAnchor)
        ignoreCollapsedWidthConstraint = ignoreButton.setWidth(0)
        ignoreCollapsedWidthConstraint?.isActive = false

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        titleDateSpacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleDateSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    private func configureActions() {
        ignoreButton.addTarget(self, action: #selector(handleIgnoreTap), for: .touchUpInside)
        acceptButton.addTarget(self, action: #selector(handleAcceptTap), for: .touchUpInside)
    }

    private func configureIcon(type: NotificationsModels.NotificationType) {
        let imageConfiguration = UIImage.SymbolConfiguration(pointSize: UIConstants.iconSize, weight: .regular)

        switch type {
        case .groupInvite:
            setRegularIcon(
                symbolName: "person.2.badge.plus.fill",
                tintColor: .accentPrimary,
                configuration: imageConfiguration
            )

        case .quizCreated:
            setRegularIcon(
                symbolName: "gamecontroller.fill",
                tintColor: .accentPrimary,
                configuration: imageConfiguration
            )

        case .quizResults:
            setRegularIcon(
                symbolName: "list.bullet.clipboard.fill",
                tintColor: .accentPrimary,
                configuration: imageConfiguration
            )

        case .gradeChanged:
            setRegularIcon(
                symbolName: "graduationcap.fill",
                tintColor: .accentPrimary,
                configuration: imageConfiguration
            )

        case .deadlineReminder:
            iconImageView.isHidden = true
            flameGradientIconView.isHidden = false
            flameGradientIconView.applyCurrentColors(using: traitCollection)

        case .groupKicked:
            setRegularIcon(
                symbolName: "person.2.badge.minus.fill",
                tintColor: .backgroundRedSecondary,
                configuration: imageConfiguration
            )

        case .unknown:
            setRegularIcon(
                symbolName: "bell.fill",
                tintColor: .textSecondary,
                configuration: imageConfiguration
            )
        }
    }

    private func setRegularIcon(
        symbolName: String,
        tintColor: UIColor,
        configuration: UIImage.SymbolConfiguration
    ) {
        iconImageView.isHidden = false
        flameGradientIconView.isHidden = true
        iconImageView.image = UIImage(systemName: symbolName, withConfiguration: configuration)?
            .withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }

    private func configureInviteActions(with notification: NotificationsModels.NotificationViewData) {
        guard notification.type == .groupInvite else {
            applyIgnoredLayout(animated: false)
            inviteActionState = .ignored
            return
        }

        let previousState = inviteActionState
        let targetState = notification.inviteActionState
        let shouldAnimate = previousState == .available && targetState != .available

        switch targetState {
        case .available:
            applyAvailableLayout(isInProgress: notification.isInviteActionInProgress)

        case .ignored:
            applyIgnoredLayout(animated: shouldAnimate)
        }

        inviteActionState = targetState
    }

    private func resetInviteActionsLayout() {
        inviteActionState = .ignored
        mainStackView.spacing = UIConstants.mainStackDefaultSpacing
        inviteActionsStackView.isHidden = true
        inviteActionsStackView.spacing = UIConstants.inviteActionsDefaultSpacing
        inviteActionsHeightConstraint?.constant = UIConstants.actionButtonHeight
        ignoreEqualWidthConstraint?.isActive = true
        ignoreCollapsedWidthConstraint?.isActive = false
        ignoreButton.isEnabled = true
        acceptButton.isEnabled = true
        ignoreButton.alpha = 1
        acceptButton.alpha = 1
        ignoreButton.setTitle("notificationsIgnoreButton".localized, for: .normal)
        acceptButton.setTitle("notificationsAcceptButton".localized, for: .normal)
    }

    private func applyAvailableLayout(isInProgress: Bool) {
        inviteActionsStackView.isHidden = false
        inviteActionsStackView.spacing = UIConstants.inviteActionsDefaultSpacing
        mainStackView.spacing = UIConstants.mainStackDefaultSpacing
        inviteActionsHeightConstraint?.constant = UIConstants.actionButtonHeight
        ignoreEqualWidthConstraint?.isActive = true
        ignoreCollapsedWidthConstraint?.isActive = false
        ignoreButton.setTitle("notificationsIgnoreButton".localized, for: .normal)
        acceptButton.setTitle("notificationsAcceptButton".localized, for: .normal)

        let isEnabled = isInProgress == false
        ignoreButton.isEnabled = isEnabled
        acceptButton.isEnabled = isEnabled
        ignoreButton.alpha = isEnabled ? 1 : 0.6
        acceptButton.alpha = isEnabled ? 1 : 0.6
        contentView.layoutIfNeeded()
    }

    private func applyIgnoredLayout(animated: Bool) {
        ignoreButton.isEnabled = false
        acceptButton.isEnabled = false

        let updates = { [weak self] in
            guard let self else { return }
            self.inviteActionsHeightConstraint?.constant = 0
            self.mainStackView.spacing = 0
            self.contentView.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { [weak self] _ in
            self?.inviteActionsStackView.isHidden = true
        }

        if animated {
            inviteActionsStackView.isHidden = false
            inviteActionsHeightConstraint?.constant = UIConstants.actionButtonHeight
            mainStackView.spacing = UIConstants.mainStackDefaultSpacing
            inviteActionsStackView.spacing = UIConstants.inviteActionsDefaultSpacing
            contentView.layoutIfNeeded()
            UIView.animate(
                withDuration: UIConstants.inviteActionsTransitionDuration,
                delay: 0,
                options: [.curveEaseInOut]
            ) {
                updates()
            } completion: { finished in
                completion(finished)
            }
        } else {
            updates()
            completion(true)
        }
    }

    // MARK: - Actions
    @objc
    private func handleIgnoreTap() {
        guard inviteActionState == .available else { return }
        onIgnoreTap?()
    }

    @objc
    private func handleAcceptTap() {
        guard inviteActionState == .available else { return }
        onAcceptTap?()
    }
}

// MARK: - FlameGradientIconView
private final class FlameGradientIconView: UIView {
    // MARK: - UI Components
    private let gradientLayer = CAGradientLayer()

    // MARK: - Constants
    private enum UIConstants {
        static let symbolName = "flame.fill"
        static let symbolSize: CGFloat = 24
    }

    private enum GradientConstants {
        static let startPoint = CGPoint(x: 0.5, y: 0)
        static let endPoint = CGPoint(x: 0.5, y: 1)
    }

    // MARK: - Properties
    private let maskLayer = CALayer()

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        updateMaskLayerFrame()
    }

    // MARK: - Methods
    func applyCurrentColors(using traitCollection: UITraitCollection) {
        let orangeColor = UIColor(named: ".backgroundOrange")
            ?? UIColor.backgroundRedSecondary
        gradientLayer.colors = [
            UIColor.backgroundRedSecondary.resolvedColor(with: traitCollection).cgColor,
            orangeColor.resolvedColor(with: traitCollection).cgColor
        ]
    }

    // MARK: - Private Methods
    private func configureUI() {
        gradientLayer.startPoint = GradientConstants.startPoint
        gradientLayer.endPoint = GradientConstants.endPoint
        gradientLayer.mask = maskLayer
        layer.addSublayer(gradientLayer)

        updateMaskLayerFrame()
    }

    private func updateMaskLayerFrame() {
        let configuration = UIImage.SymbolConfiguration(
            pointSize: UIConstants.symbolSize,
            weight: .regular
        )

        guard let image = UIImage(systemName: UIConstants.symbolName, withConfiguration: configuration),
              let cgImage = image.cgImage else {
            return
        }

        maskLayer.contents = cgImage
        maskLayer.contentsScale = traitCollection.displayScale
        maskLayer.bounds = CGRect(origin: .zero, size: image.size)
        maskLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
