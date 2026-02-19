//
//  AvatarPickerView.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.02.2026.
//

import UIKit

final class AvatarPickerView: UIView {
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.setWidth(75)
        view.setHeight(75)
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = .avatarPlaceholder
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 37.5
        imageView.layer.borderWidth = 1.5
        imageView.layer.borderColor = UIColor.accentPrimary.cgColor
        imageView.isUserInteractionEnabled = false
        return imageView
    }()

    private let avatarMenuButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private let editAvatarButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(font: .systemFont(ofSize: 20, weight: .regular))
        let image = UIImage(systemName: "pencil.circle.fill", withConfiguration: configuration)
        button.setImage(image, for: .normal)
        button.tintColor = .textPrimary
        button.showsMenuAsPrimaryAction = true
        button.backgroundColor = .clear
        return button
    }()

    // MARK: - Properties
    private var isAvatarSet: Bool = false

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
    func setMenu(_ menu: UIMenu) {
        avatarMenuButton.menu = menu
        editAvatarButton.menu = menu
    }

    func setAvatar(_ image: UIImage?) {
        if let image {
            isAvatarSet = true
            avatarImageView.image = image
        } else {
            isAvatarSet = false
            avatarImageView.image = .avatarPlaceholder
        }
    }

    func hasAvatar() -> Bool {
        isAvatarSet
    }

    // MARK: - Private Methods
    private func configureUI() {
        addSubview(containerView)
        containerView.pin(to: self)

        containerView.addSubview(avatarImageView)
        avatarImageView.pin(to: containerView)

        containerView.addSubview(avatarMenuButton)
        avatarMenuButton.pin(to: containerView)

        containerView.addSubview(editAvatarButton)
        editAvatarButton.pinRight(to: containerView.trailingAnchor, -6)
        editAvatarButton.pinBottom(to: containerView.bottomAnchor, -6)
    }
}
