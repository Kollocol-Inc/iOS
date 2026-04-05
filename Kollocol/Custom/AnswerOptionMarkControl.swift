//
//  AnswerOptionMarkControl.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.03.2026.
//

import UIKit

final class AnswerOptionMarkControl: UIControl {
    // MARK: - Typealias
    enum Kind {
        case singleChoice
        case multipleChoice
    }

    enum Size {
        case compact
        case regular
    }

    enum VisualState {
        case neutral
        case correct
        case incorrect
    }

    struct Configuration {
        let kind: Kind
        let size: Size
        let visualState: VisualState
        let isSelected: Bool
    }

    // MARK: - UI Components
    private let innerCircleView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor.backgroundSecondary.cgColor
        view.isHidden = true
        return view
    }()

    private let symbolImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private let loadingOverlayView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }()

    private let loadingRotatedLayer = CALayer()
    private let loadingReplicator = CAReplicatorLayer()
    private let loadingStripe = CALayer()

    // MARK: - Constants
    private enum UIConstants {
        static let compactSide: CGFloat = 14
        static let regularSide: CGFloat = 18

        static let compactSingleInnerSide: CGFloat = 10
        static let regularSingleInnerSide: CGFloat = 14

        static let compactMultipleCornerRadius: CGFloat = 3
        static let regularMultipleCornerRadius: CGFloat = 4

        static let borderWidth: CGFloat = 1.5
        static let compactSymbolPointSize: CGFloat = 8
        static let regularSymbolPointSize: CGFloat = 9

        static let loadingStripeWidth: CGFloat = 4
        static let loadingStripeSpacing: CGFloat = 4
        static let loadingStripeAlpha: CGFloat = 0.28
        static let loadingAnimationDuration: CFTimeInterval = 2.6
        static let loadingAnimationKey = "striped_loading_shift"
    }

    // MARK: - Properties
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var isLoadingAnimationRunning = false
    private var previousUserInteractionEnabled = true

    private var configuration: Configuration = .init(
        kind: .singleChoice,
        size: .compact,
        visualState: .neutral,
        isSelected: false
    ) {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            applyConfiguration()
        }
    }

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
        applyConfiguration()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutInnerViews()
        loadingOverlayView.frame = bounds
        loadingOverlayView.layer.cornerRadius = layer.cornerRadius
        loadingOverlayView.layer.masksToBounds = true

        if isLoadingAnimationRunning {
            updateLoadingStripesLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        let side = sideLength(for: configuration.size)
        return CGSize(width: side, height: side)
    }

    // MARK: - Methods
    func apply(configuration: Configuration) {
        self.configuration = configuration
    }

    func startAnimating() {
        guard isLoadingAnimationRunning == false else {
            return
        }

        isLoadingAnimationRunning = true
        previousUserInteractionEnabled = isUserInteractionEnabled
        isUserInteractionEnabled = false

        loadingOverlayView.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        updateLoadingStripesLayout()

        let period = UIConstants.loadingStripeWidth + UIConstants.loadingStripeSpacing
        loadingReplicator.removeAnimation(forKey: UIConstants.loadingAnimationKey)
        loadingReplicator.sublayerTransform = CATransform3DIdentity

        let animation = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
        animation.fromValue = 0
        animation.toValue = period
        animation.duration = UIConstants.loadingAnimationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        loadingReplicator.add(animation, forKey: UIConstants.loadingAnimationKey)
    }

    func stopAnimating() {
        guard isLoadingAnimationRunning else {
            return
        }

        isLoadingAnimationRunning = false
        loadingReplicator.removeAnimation(forKey: UIConstants.loadingAnimationKey)
        loadingOverlayView.isHidden = true
        isUserInteractionEnabled = previousUserInteractionEnabled
    }

    // MARK: - Private Methods
    private func configureUI() {
        clipsToBounds = true
        layer.borderWidth = UIConstants.borderWidth
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        addSubview(innerCircleView)
        addSubview(symbolImageView)
        addSubview(loadingOverlayView)
        loadingOverlayView.layer.addSublayer(loadingRotatedLayer)
        loadingRotatedLayer.addSublayer(loadingReplicator)
        loadingReplicator.addSublayer(loadingStripe)

        loadingStripe.backgroundColor = UIColor.systemGray.withAlphaComponent(UIConstants.loadingStripeAlpha).cgColor
        loadingReplicator.masksToBounds = false

        let side = sideLength(for: configuration.size)
        widthConstraint = widthAnchor.constraint(equalToConstant: side)
        heightConstraint = heightAnchor.constraint(equalToConstant: side)
        widthConstraint?.isActive = true
        heightConstraint?.isActive = true
    }

    private func applyConfiguration() {
        let side = sideLength(for: configuration.size)
        let isMarked = configuration.isSelected
        widthConstraint?.constant = side
        heightConstraint?.constant = side

        layer.cornerRadius = cornerRadius(for: configuration.kind, side: side, size: configuration.size)
        layer.borderWidth = UIConstants.borderWidth

        if isMarked {
            layer.borderColor = UIColor.clear.cgColor
            backgroundColor = fillColor(for: configuration.visualState)
        } else {
            layer.borderColor = UIColor.dividerPrimary.cgColor
            backgroundColor = .clear
        }

        switch configuration.kind {
        case .singleChoice:
            innerCircleView.isHidden = !isMarked
            symbolImageView.isHidden = true

            let innerSide = innerSideForSingleChoice(for: configuration.size)
            innerCircleView.layer.cornerRadius = innerSide / 2

        case .multipleChoice:
            innerCircleView.isHidden = true
            symbolImageView.isHidden = !isMarked
            symbolImageView.image = symbolImage(for: configuration)
        }
    }

    private func layoutInnerViews() {
        let boundsCenterX = bounds.midX
        let boundsCenterY = bounds.midY

        let innerSide = innerSideForSingleChoice(for: configuration.size)
        innerCircleView.frame = CGRect(
            x: boundsCenterX - innerSide / 2,
            y: boundsCenterY - innerSide / 2,
            width: innerSide,
            height: innerSide
        )

        symbolImageView.frame = bounds
    }

    private func sideLength(for size: Size) -> CGFloat {
        switch size {
        case .compact:
            return UIConstants.compactSide
        case .regular:
            return UIConstants.regularSide
        }
    }

    private func innerSideForSingleChoice(for size: Size) -> CGFloat {
        switch size {
        case .compact:
            return UIConstants.compactSingleInnerSide
        case .regular:
            return UIConstants.regularSingleInnerSide
        }
    }

    private func cornerRadius(for kind: Kind, side: CGFloat, size: Size) -> CGFloat {
        switch kind {
        case .singleChoice:
            return side / 2
        case .multipleChoice:
            switch size {
            case .compact:
                return UIConstants.compactMultipleCornerRadius
            case .regular:
                return UIConstants.regularMultipleCornerRadius
            }
        }
    }

    private func fillColor(for visualState: VisualState) -> UIColor {
        switch visualState {
        case .neutral:
            return .accentPrimary
        case .correct:
            return .backgroundGreen
        case .incorrect:
            return .backgroundRedSecondary
        }
    }

    private func symbolImage(for configuration: Configuration) -> UIImage? {
        let symbolName: String = configuration.visualState == .incorrect ? "xmark" : "checkmark"
        let pointSize: CGFloat = {
            switch configuration.size {
            case .compact:
                return UIConstants.compactSymbolPointSize
            case .regular:
                return UIConstants.regularSymbolPointSize
            }
        }()

        let symbolConfiguration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: pointSize, weight: .medium)
        )

        return UIImage(systemName: symbolName, withConfiguration: symbolConfiguration)?
            .withTintColor(.backgroundSecondary, renderingMode: .alwaysOriginal)
    }

    private func updateLoadingStripesLayout() {
        let extra = max(bounds.width, bounds.height)
        let bigBounds = bounds.insetBy(dx: -extra, dy: -extra)

        loadingRotatedLayer.bounds = bigBounds
        loadingRotatedLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        loadingRotatedLayer.transform = CATransform3DMakeRotation(.pi / 4, 0, 0, 1)

        loadingReplicator.frame = loadingRotatedLayer.bounds

        loadingStripe.frame = CGRect(
            x: 0,
            y: 0,
            width: UIConstants.loadingStripeWidth,
            height: loadingReplicator.bounds.height
        )

        let period = UIConstants.loadingStripeWidth + UIConstants.loadingStripeSpacing
        loadingReplicator.instanceTransform = CATransform3DMakeTranslation(period, 0, 0)
        loadingReplicator.instanceCount = Int(ceil(loadingReplicator.bounds.width / period)) + 3
    }
}
