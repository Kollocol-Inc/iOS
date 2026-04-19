//
//  QuizParticipantReviewScoreControlView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.04.2026.
//

import UIKit

private final class ExpandedHitAreaButton: UIButton {
    var extraTouchInset: CGFloat = 16

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard isHidden == false,
              alpha > 0.01,
              isUserInteractionEnabled,
              isEnabled else {
            return false
        }

        let expandedBounds = bounds.insetBy(dx: -extraTouchInset, dy: -extraTouchInset)
        return expandedBounds.contains(point)
    }
}

final class QuizParticipantReviewScoreControlView: UIView {
    // MARK: - UI Components
    private let minusButton: ExpandedHitAreaButton = {
        let button = ExpandedHitAreaButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 16, weight: .regular)
        )
        let image = UIImage(systemName: "minus", withConfiguration: configuration)?
            .withTintColor(.textWhite, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    private let scoreTextField: UITextField = {
        let field = UITextField()
        field.font = .systemFont(ofSize: 14, weight: .semibold)
        field.textColor = .textWhite
        field.textAlignment = .center
        field.keyboardType = .numberPad
        field.tintColor = .textWhite
        return field
    }()

    private let plusButton: ExpandedHitAreaButton = {
        let button = ExpandedHitAreaButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(
            font: .systemFont(ofSize: 16, weight: .regular)
        )
        let image = UIImage(systemName: "plus", withConfiguration: configuration)?
            .withTintColor(.textWhite, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        return button
    }()

    // MARK: - Properties
    var onMinusTap: (() -> Void)?
    var onPlusTap: (() -> Void)?
    var onScoreInputCommit: ((String?) -> Void)?

    private var currentScore = 0

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods
    func configure(
        score: Int,
        isMinusEnabled: Bool,
        isPlusEnabled: Bool
    ) {
        if score != currentScore {
            animateScoreTransition(from: currentScore, to: score)
            currentScore = score
        } else {
            scoreTextField.text = "\(score)"
        }

        minusButton.isEnabled = isMinusEnabled
        minusButton.alpha = isMinusEnabled ? 1 : 0.6

        plusButton.isEnabled = isPlusEnabled
        plusButton.alpha = isPlusEnabled ? 1 : 0.6
    }

    var currentInputText: String? {
        scoreTextField.text
    }

    // MARK: - Private Methods
    private func configureUI() {
        backgroundColor = .buttonSecondary
        layer.cornerRadius = 18
        clipsToBounds = true

        addSubview(minusButton)
        addSubview(scoreTextField)
        addSubview(plusButton)

        minusButton.pinLeft(to: leadingAnchor, 10)
        minusButton.pinCenterY(to: centerYAnchor)
        minusButton.setWidth(16)
        minusButton.setHeight(16)

        plusButton.pinRight(to: trailingAnchor, 10)
        plusButton.pinCenterY(to: centerYAnchor)
        plusButton.setWidth(16)
        plusButton.setHeight(16)

        scoreTextField.pinTop(to: topAnchor)
        scoreTextField.pinBottom(to: bottomAnchor)
        scoreTextField.pinLeft(to: minusButton.trailingAnchor, 8)
        scoreTextField.pinRight(to: plusButton.leadingAnchor, 8)

        minusButton.addTarget(self, action: #selector(handleMinusTap), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(handlePlusTap), for: .touchUpInside)
        scoreTextField.delegate = self
    }

    private func animateScoreTransition(from oldValue: Int, to newValue: Int) {
        let transition = CATransition()
        transition.type = .push
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.subtype = newValue > oldValue ? .fromBottom : .fromTop
        scoreTextField.layer.add(transition, forKey: "scoreChangePush")
        scoreTextField.text = "\(newValue)"
    }

    // MARK: - Actions
    @objc
    private func handleMinusTap() {
        onMinusTap?()
    }

    @objc
    private func handlePlusTap() {
        onPlusTap?()
    }

}

// MARK: - UITextFieldDelegate
extension QuizParticipantReviewScoreControlView: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        onScoreInputCommit?(textField.text)
    }
}
