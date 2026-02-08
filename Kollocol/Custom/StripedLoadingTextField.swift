//
//  StripedLoadingTextField.swift
//  Kollocol
//
//  Created by Arseniy on 07.02.2026.
//

import UIKit

final class StripedLoadingTextField: UITextField {
    // MARK: - Config
    private let stripeWidth: CGFloat = 10
    private let stripeSpacing: CGFloat = 10
    private let stripeAlpha: CGFloat = 0.28
    private let animationDuration: CFTimeInterval = 2.6
    private let animationKey = "striped_loading_shift"

    // MARK: - Layers / Views
    private let overlayView = UIView()
    private let rotatedLayer = CALayer()
    private let replicator = CAReplicatorLayer()
    private let stripe = CALayer()

    // MARK: - State
    private var isAnimating = false
    private var previousUserInteractionEnabled: Bool = true

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        overlayView.isHidden = true
        overlayView.isUserInteractionEnabled = false
        overlayView.backgroundColor = .clear
        addSubview(overlayView)

        overlayView.layer.addSublayer(rotatedLayer)
        rotatedLayer.addSublayer(replicator)
        replicator.addSublayer(stripe)

        stripe.backgroundColor = UIColor.systemGray.withAlphaComponent(stripeAlpha).cgColor
        replicator.masksToBounds = false
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        overlayView.frame = bounds
        overlayView.layer.cornerRadius = layer.cornerRadius
        overlayView.layer.masksToBounds = true

        if isAnimating {
            updateStripesLayout()
        }
    }

    private func updateStripesLayout() {
        let extra = max(bounds.width, bounds.height)
        let bigBounds = bounds.insetBy(dx: -extra, dy: -extra)

        rotatedLayer.bounds = bigBounds
        rotatedLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        rotatedLayer.transform = CATransform3DMakeRotation(.pi / 4, 0, 0, 1)

        replicator.frame = rotatedLayer.bounds

        stripe.frame = CGRect(x: 0, y: 0, width: stripeWidth, height: replicator.bounds.height)

        let period = stripeWidth + stripeSpacing
        replicator.instanceTransform = CATransform3DMakeTranslation(period, 0, 0)
        replicator.instanceCount = Int(ceil(replicator.bounds.width / period)) + 3
    }

    // MARK: - Public API
    func startAnimating() {
        guard !isAnimating else { return }
        isAnimating = true

        resignFirstResponder()

        previousUserInteractionEnabled = isUserInteractionEnabled
        isUserInteractionEnabled = false

        overlayView.isHidden = false
        setNeedsLayout()
        layoutIfNeeded()
        updateStripesLayout()

        let period = stripeWidth + stripeSpacing

        replicator.removeAnimation(forKey: animationKey)
        replicator.sublayerTransform = CATransform3DIdentity

        let anim = CABasicAnimation(keyPath: "sublayerTransform.translation.x")
        anim.fromValue = 0
        anim.toValue = period
        anim.duration = animationDuration
        anim.repeatCount = .infinity
        anim.timingFunction = CAMediaTimingFunction(name: .linear)
        replicator.add(anim, forKey: animationKey)
    }

    func stopAnimating() {
        guard isAnimating else { return }
        isAnimating = false

        replicator.removeAnimation(forKey: animationKey)
        overlayView.isHidden = true

        isUserInteractionEnabled = previousUserInteractionEnabled
    }
}

