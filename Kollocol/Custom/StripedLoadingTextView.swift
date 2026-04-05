//
//  StripedLoadingTextView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 05.04.2026.
//

import UIKit

final class StripedLoadingTextView: UITextView {
    // MARK: - UI Components
    private let overlayView = UIView()

    private let rotatedLayer = CALayer()
    private let replicator = CAReplicatorLayer()
    private let stripe = CALayer()

    // MARK: - Constants
    private enum UIConstants {
        static let stripeWidth: CGFloat = 10
        static let stripeSpacing: CGFloat = 10
        static let stripeAlpha: CGFloat = 0.28
        static let animationDuration: CFTimeInterval = 2.6
        static let animationKey = "striped_loading_shift"
    }

    // MARK: - Properties
    private var isAnimating = false
    private var previousUserInteractionEnabled = true

    // MARK: - Lifecycle
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        overlayView.frame = bounds
        overlayView.layer.cornerRadius = layer.cornerRadius
        overlayView.layer.masksToBounds = true

        if isAnimating {
            updateStripesLayout()
        }
    }

    // MARK: - Methods
    func startAnimating() {
        guard isAnimating == false else {
            return
        }

        isAnimating = true
        resignFirstResponder()

        previousUserInteractionEnabled = isUserInteractionEnabled
        isUserInteractionEnabled = false

        overlayView.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        updateStripesLayout()

        let period = UIConstants.stripeWidth + UIConstants.stripeSpacing

        replicator.removeAnimation(forKey: UIConstants.animationKey)
        replicator.sublayerTransform = CATransform3DIdentity

        let animation = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
        animation.fromValue = 0
        animation.toValue = period
        animation.duration = UIConstants.animationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        replicator.add(animation, forKey: UIConstants.animationKey)
    }

    func stopAnimating() {
        guard isAnimating else {
            return
        }

        isAnimating = false
        replicator.removeAnimation(forKey: UIConstants.animationKey)
        overlayView.isHidden = true
        isUserInteractionEnabled = previousUserInteractionEnabled
    }

    // MARK: - Private Methods
    private func commonInit() {
        overlayView.isHidden = true
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = .clear
        addSubview(overlayView)

        overlayView.layer.addSublayer(rotatedLayer)
        rotatedLayer.addSublayer(replicator)
        replicator.addSublayer(stripe)

        stripe.backgroundColor = UIColor.systemGray.withAlphaComponent(UIConstants.stripeAlpha).cgColor
        replicator.masksToBounds = false
    }

    private func updateStripesLayout() {
        let extra = max(bounds.width, bounds.height)
        let bigBounds = bounds.insetBy(dx: -extra, dy: -extra)

        rotatedLayer.bounds = bigBounds
        rotatedLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        rotatedLayer.transform = CATransform3DMakeRotation(.pi / 4, 0, 0, 1)

        replicator.frame = rotatedLayer.bounds

        stripe.frame = CGRect(
            x: 0,
            y: 0,
            width: UIConstants.stripeWidth,
            height: replicator.bounds.height
        )

        let period = UIConstants.stripeWidth + UIConstants.stripeSpacing
        replicator.instanceTransform = CATransform3DMakeTranslation(period, 0, 0)
        replicator.instanceCount = Int(ceil(replicator.bounds.width / period)) + 3
    }
}
