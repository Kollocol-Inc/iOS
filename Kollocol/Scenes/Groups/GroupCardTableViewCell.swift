import UIKit
import Kingfisher
import ShimmerView

final class GroupCardTableViewCell: UITableViewCell {
    // MARK: - UI Components
    private let groupCardView = GroupCardView()

    // MARK: - Constants
    static let reuseIdentifier = "GroupCardTableViewCell"

    private enum UIConstants {
        static let horizontalInset: CGFloat = 24
        static let topInset: CGFloat = 12
        static let cardHeight: CGFloat = 70
    }

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
        groupCardView.prepareForReuse()
    }

    // MARK: - Methods
    func configure(with item: GroupsModels.GroupViewData) {
        groupCardView.configure(with: item)
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
    }
}

private final class GroupCardView: UIView {
    // MARK: - UI Components
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22.5
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.clipsToBounds = true
        imageView.backgroundColor = .backgroundSecondary
        return imageView
    }()

    private let avatarShimmerView = ShimmerView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textPrimary
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .textSecondary
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.isHidden = true
        return label
    }()

    private let titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .fill
        return stackView
    }()

    private let memberCountLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let pendingInvitesLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    private let countsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .leading
        return stackView
    }()

    private let chevronImageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(font: UIFont.systemFont(ofSize: 20, weight: .medium))
        let image = UIImage(systemName: "chevron.right", withConfiguration: configuration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)
        return UIImageView(image: image)
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let cornerRadius: CGFloat = 18
        static let shadowRadius: CGFloat = 20
        static let shadowOpacity: Float = 0.2

        static let avatarLeftInset: CGFloat = 16
        static let avatarSize: CGFloat = 45
        static let titleSpacingFromAvatar: CGFloat = 8

        static let chevronRightInset: CGFloat = 12
        static let countsSpacingFromChevron: CGFloat = 8
        static let titleSpacingFromCounts: CGFloat = 8

        static let countFontSize: CGFloat = 14
    }

    // MARK: - Properties
    private var isAvatarShimmerAnimating = false

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        guard isAvatarShimmerAnimating else { return }
        avatarShimmerView.apply(style: makeAvatarShimmerStyle(for: traitCollection))
    }

    // MARK: - Methods
    func configure(with item: GroupsModels.GroupViewData) {
        titleLabel.text = item.title
        let normalizedSubtitle = item.subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalizedSubtitle, normalizedSubtitle.isEmpty == false {
            subtitleLabel.text = normalizedSubtitle
            subtitleLabel.isHidden = false
        } else {
            subtitleLabel.text = nil
            subtitleLabel.isHidden = true
        }

        memberCountLabel.attributedText = makeCountText(
            count: item.memberCount,
            symbolName: "person.2.fill"
        )
        pendingInvitesLabel.attributedText = makeCountText(
            count: item.pendingInvitesCount,
            symbolName: "person.badge.clock.fill"
        )
        pendingInvitesLabel.isHidden = item.pendingInvitesCount == 0

        loadAvatar(from: item.avatarUrl)
    }

    func prepareForReuse() {
        avatarImageView.kf.cancelDownloadTask()
        stopAvatarShimmer()
        avatarImageView.image = UIImage(named: "groupsAvatarPlaceholder")
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .backgroundCardPrimary
        layer.cornerRadius = UIConstants.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowRadius = UIConstants.shadowRadius
        layer.shadowOpacity = UIConstants.shadowOpacity
        clipsToBounds = false

        configureTitleStackView()
        configureCountsStackView()
        configureConstraints()
    }

    private func configureTitleStackView() {
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(subtitleLabel)
    }

    private func configureCountsStackView() {
        countsStackView.addArrangedSubview(memberCountLabel)
        countsStackView.addArrangedSubview(pendingInvitesLabel)

        countsStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        countsStackView.setContentHuggingPriority(.required, for: .horizontal)
        memberCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        memberCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        pendingInvitesLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        pendingInvitesLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func configureConstraints() {
        addSubview(chevronImageView)
        chevronImageView.pinRight(to: trailingAnchor, UIConstants.chevronRightInset)
        chevronImageView.pinCenterY(to: centerYAnchor)

        addSubview(countsStackView)
        countsStackView.pinRight(to: chevronImageView.leadingAnchor, UIConstants.countsSpacingFromChevron)
        countsStackView.pinCenterY(to: centerYAnchor)

        addSubview(avatarImageView)
        avatarImageView.pinLeft(to: leadingAnchor, UIConstants.avatarLeftInset)
        avatarImageView.pinCenterY(to: centerYAnchor)
        avatarImageView.setWidth(UIConstants.avatarSize)
        avatarImageView.setHeight(UIConstants.avatarSize)

        avatarImageView.addSubview(avatarShimmerView)
        avatarShimmerView.pin(to: avatarImageView)
        avatarShimmerView.layer.cornerRadius = UIConstants.avatarSize / 2
        avatarShimmerView.layer.masksToBounds = true
        avatarShimmerView.isHidden = true

        addSubview(titleStackView)
        titleStackView.pinLeft(to: avatarImageView.trailingAnchor, UIConstants.titleSpacingFromAvatar)
        titleStackView.pinRight(to: countsStackView.leadingAnchor, UIConstants.titleSpacingFromCounts, .lsOE)
        titleStackView.pinCenterY(to: centerYAnchor)
    }

    private func loadAvatar(from avatarUrl: String?) {
        let placeholderImage = UIImage(named: "groupsAvatarPlaceholder")
        let normalizedAvatarUrl = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard normalizedAvatarUrl.isEmpty == false, let url = URL(string: normalizedAvatarUrl) else {
            avatarImageView.kf.cancelDownloadTask()
            stopAvatarShimmer()
            avatarImageView.image = placeholderImage
            return
        }

        startAvatarShimmer()
        avatarImageView.kf.setImage(
            with: url,
            placeholder: placeholderImage,
            options: [
                .transition(.fade(0.25)),
                .cacheOriginalImage
            ]
        ) { [weak self] result in
            guard let self else { return }
            if case .failure = result {
                self.avatarImageView.image = placeholderImage
            }
            self.stopAvatarShimmer()
        }
    }

    private func makeCountText(count: Int, symbolName: String) -> NSAttributedString {
        let normalizedCount = max(0, count)
        let font = UIFont.systemFont(ofSize: UIConstants.countFontSize, weight: .medium)
        let text = NSMutableAttributedString(
            string: "\(normalizedCount) ",
            attributes: [
                .font: font,
                .foregroundColor: UIColor.textPrimary
            ]
        )

        let configuration = UIImage.SymbolConfiguration(font: font)
        let iconImage = UIImage(systemName: symbolName, withConfiguration: configuration)?
            .withTintColor(.accentPrimary, renderingMode: .alwaysOriginal)

        if let iconImage {
            let attachment = NSTextAttachment()
            attachment.image = iconImage
            text.append(NSAttributedString(attachment: attachment))
        }

        return text
    }

    private func makeAvatarShimmerStyle(for traitCollection: UITraitCollection) -> ShimmerViewStyle {
        ShimmerViewStyle(
            baseColor: UIColor.backgroundSecondary.resolvedColor(with: traitCollection),
            highlightColor: UIColor.backgroundPrimary.resolvedColor(with: traitCollection),
            duration: 1.2,
            interval: 0.4,
            effectSpan: .points(120),
            effectAngle: 0 * CGFloat.pi
        )
    }

    private func startAvatarShimmer() {
        isAvatarShimmerAnimating = true
        avatarShimmerView.isHidden = false
        avatarShimmerView.apply(style: makeAvatarShimmerStyle(for: traitCollection))
        avatarShimmerView.startAnimating()
    }

    private func stopAvatarShimmer() {
        isAvatarShimmerAnimating = false
        avatarShimmerView.stopAnimating()
        avatarShimmerView.isHidden = true
    }
}
