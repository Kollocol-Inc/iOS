//
//  RegistrationViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import PhotosUI

final class RegistrationViewController: UIViewController {
    // MARK: - Typealias
    typealias AvatarPayload = (image: UIImage, data: Data?)
    
    // MARK: - UI Components
    private let kollocolLabel: UILabel = {
        let label = UILabel()
        label.text = "Kollocol"
        label.textColor = .textSecondary
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let registrationLabel: UILabel = {
        let label = UILabel()
        label.text = "Регистрация"
        label.textColor = .textPrimary
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 1
        return label
    }()
    
    private let avatarRowView: UIView = {
        let view = UIView()
        view.setHeight(75)
        return view
    }()
    
    private let avatarContainerView: UIView = {
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
    
    private let nameTextField: StripedLoadingTextField = {
        let field = StripedLoadingTextField()
        let attributedPlaceholder = NSAttributedString(
            string: "Имя",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
        )
        field.attributedPlaceholder = attributedPlaceholder
        field.autocorrectionType = .default
        field.autocapitalizationType = .words
        field.keyboardType = .default
        field.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        field.textColor = .textPrimary
        field.backgroundColor = .dividerPrimary
        field.addPadding(side: 10)
        field.layer.cornerRadius = 18
        field.setHeight(38)
        return field
    }()
    
    private let surnameTextField: StripedLoadingTextField = {
        let field = StripedLoadingTextField()
        let attributedPlaceholder = NSAttributedString(
            string: "Фамилия",
            attributes: [
                .foregroundColor: UIColor.textSecondary,
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ]
        )
        field.attributedPlaceholder = attributedPlaceholder
        field.autocorrectionType = .default
        field.autocapitalizationType = .words
        field.keyboardType = .default
        field.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        field.textColor = .textPrimary
        field.backgroundColor = .dividerPrimary
        field.addPadding(side: 10)
        field.layer.cornerRadius = 18
        field.setHeight(38)
        return field
    }()
    
    private let centralStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        return stack
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setAttributedTitle(Constants.RegisterButtonTitles.disabled, for: .disabled)
        button.setAttributedTitle(Constants.RegisterButtonTitles.active, for: .normal)
        button.tintColor = .textWhite
        button.backgroundColor = .accentPrimary
        button.layer.cornerRadius = 18
        button.isEnabled = false
        button.alpha = 0.6
        button.setHeight(42)
        return button
    }()
    
    private lazy var registerLoader: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.color = .textWhite
        view.hidesWhenStopped = true
        return view
    }()
    
    // MARK: - Constants
    private let baseButtonBottomInset: Double = 30
    private let keyboardSpacing: Double = 12
    
    // MARK: - Properties
    private var interactor: RegistrationInteractor
    
    private var avatarPayload: AvatarPayload?
    
    private var registerButtonBottomConstraint: NSLayoutConstraint?
    private var centralStackCenterYConstraint: NSLayoutConstraint?
    private var centralStackBottomToButtonConstraint: NSLayoutConstraint?
    
    // MARK: - Lifecycle
    init(interactor: RegistrationInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnBackgroundTap()
        configureUI()
        updateAvatarMenu()
        configureKeyboardObservers()
    }
    
    // MARK: - Methods
    @MainActor
    func unlockFieldsAndButtons() {
        stopLoadingState()
    }
    
    @MainActor
    func deleteAvatar() {
        avatarPayload = nil
        avatarImageView.image = .avatarPlaceholder
        updateAvatarMenu()
    }
    
    @MainActor
    func applyCroppedAvatar(_ image: UIImage) {
        avatarImageView.image = image
        avatarPayload = (image: image, data: image.jpegData(compressionQuality: 0.8))
        updateAvatarMenu()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureActions()
        configureTextFields()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    private func configureConstraints() {
        view.addSubview(kollocolLabel)
        kollocolLabel.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        kollocolLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, 70)

        view.addSubview(centralStack)
        centralStack.addArrangedSubview(registrationLabel)
        centralStack.addArrangedSubview(avatarRowView)
        centralStack.addArrangedSubview(nameTextField)
        centralStack.addArrangedSubview(surnameTextField)

        centralStackCenterYConstraint = centralStack.pinCenterY(to: view.safeAreaLayoutGuide.centerYAnchor)
        centralStack.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        centralStack.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 16)
        
        avatarRowView.addSubview(avatarContainerView)
        avatarContainerView.pinCenterX(to: avatarRowView.centerXAnchor)
        avatarContainerView.pinTop(to: avatarRowView.topAnchor)

        avatarContainerView.addSubview(avatarImageView)
        avatarImageView.pin(to: avatarContainerView)

        avatarContainerView.addSubview(avatarMenuButton)
        avatarMenuButton.pin(to: avatarContainerView)

        avatarContainerView.addSubview(editAvatarButton)
        editAvatarButton.pinRight(to: avatarContainerView.trailingAnchor, -6)
        editAvatarButton.pinBottom(to: avatarContainerView.bottomAnchor, -6)

        view.addSubview(registerButton)
        registerButton.pinCenterX(to: view.safeAreaLayoutGuide.centerXAnchor)
        registerButton.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, 16)

        registerButtonBottomConstraint = registerButton.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor, baseButtonBottomInset)

        registerButton.addSubview(registerLoader)
        registerLoader.pinCenter(to: registerButton)

        centralStackBottomToButtonConstraint = centralStack.pinBottom(to: registerButton.topAnchor, keyboardSpacing)
        centralStackBottomToButtonConstraint?.isActive = false
    }
    
    private func configureTextFields() {
        nameTextField.returnKeyType = .done
        nameTextField.enablesReturnKeyAutomatically = true
        nameTextField.delegate = self
        
        surnameTextField.returnKeyType = .done
        surnameTextField.enablesReturnKeyAutomatically = true
        surnameTextField.delegate = self
    }
    
    private func configureActions() {
        nameTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)
        surnameTextField.addTarget(self, action: #selector(textFieldsDidChange), for: .editingChanged)

        registerButton.addTarget(self, action: #selector(registerButtonPressed), for: .touchUpInside)
    }
    
    private func configureKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func applyKeyboardLayout(lift: CGFloat, duration: Double, options: UIView.AnimationOptions) {
        let isVisible = lift > 0.5

        if isVisible {
            registerButtonBottomConstraint?.constant = -(lift + CGFloat(keyboardSpacing))
            centralStackCenterYConstraint?.isActive = false
            centralStackBottomToButtonConstraint?.isActive = true
        } else {
            registerButtonBottomConstraint?.constant = -CGFloat(baseButtonBottomInset)
            centralStackBottomToButtonConstraint?.isActive = false
            centralStackCenterYConstraint?.isActive = true
        }

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateRegisterButtonState() {
        let nameCount = nameTextField.text?.count ?? 0
        let surnameCount = surnameTextField.text?.count ?? 0
        let isValid = nameCount >= 2 && surnameCount >= 2

        UIView.performWithoutAnimation {
            registerButton.isEnabled = isValid
            registerButton.alpha = isValid ? 1 : 0.6
            registerButton.layoutIfNeeded()
        }
    }
    
    private func startLoadingState() {
        registerButton.isEnabled = false
        registerButton.setAttributedTitle(nil, for: .normal)
        registerButton.setAttributedTitle(nil, for: .disabled)
        registerLoader.startAnimating()

        nameTextField.startAnimating()
        surnameTextField.startAnimating()
    }
    
    private func stopLoadingState() {
        registerButton.setAttributedTitle(Constants.RegisterButtonTitles.active, for: .normal)
        registerButton.setAttributedTitle(Constants.RegisterButtonTitles.disabled, for: .disabled)
        registerLoader.stopAnimating()

        nameTextField.stopAnimating()
        surnameTextField.stopAnimating()

        updateRegisterButtonState()
    }
    
    private func updateAvatarMenu() {
        let galleryImage = UIImage(systemName: "photo.on.rectangle.angled.fill")
        let cameraImage = UIImage(systemName: "camera.fill")
        let trashImage = UIImage(systemName: "trash.fill")

        let galleryAction = UIAction(title: "Галерея", image: galleryImage) { [weak self] _ in
            self?.presentGalleryPicker()
        }

        let cameraAction = UIAction(title: "Сделать фото", image: cameraImage) { [weak self] _ in
            self?.presentCameraPicker()
        }

        var actions: [UIAction] = [galleryAction, cameraAction]

        if avatarPayload != nil {
            let deleteAction = UIAction(
                title: "Удалить фото",
                image: trashImage,
                attributes: [.destructive]
            ) { [weak self] _ in
                Task { [weak self] in
                    await self?.interactor.requestDeleteAvatarConfirmation()
                }
            }
            actions.append(deleteAction)
        }

        let menu = UIMenu(title: "", children: actions)
        avatarMenuButton.menu = menu
        editAvatarButton.menu = menu
    }
    
    private func setAvatar(image: UIImage) {
        avatarImageView.image = image

        avatarPayload = (image: image, data: image.jpegData(compressionQuality: 0.8))

        updateAvatarMenu()
    }
    
    private func presentGalleryPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func openCrop(with image: UIImage) {
        Task { @MainActor in
            await interactor.openAvatarCrop(with: image)
        }
    }
    
    // MARK: - Actions
    @objc
    private func registerButtonPressed() {
        guard let name = nameTextField.text, let surname = surnameTextField.text else { return }

        startLoadingState()

        let avatarData = avatarPayload?.data
        Task { await interactor.register(name: name, surname: surname, avatarData: avatarData) }
    }

    @objc
    private func textFieldsDidChange() {
        updateRegisterButtonState()
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let change = KeyboardChange(notification) else { return }

        let keyboardFrame = view.convert(change.endFrame, from: nil)
        let keyboardTop = keyboardFrame.minY
        let safeAreaBottom = view.safeAreaLayoutGuide.layoutFrame.maxY
        let lift = max(0, safeAreaBottom - keyboardTop)

        applyKeyboardLayout(lift: lift, duration: change.duration, options: change.options)
    }
}

private enum Constants {
    enum RegisterButtonTitles {
        static let disabled = NSAttributedString(
            string: "Укажи имя и фамилию",
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )

        static let active = NSAttributedString(
            string: "Зарегистрироваться",
            attributes: [
                .foregroundColor: UIColor.textWhite,
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold)
            ]
        )
    }
}

// MARK: - UITextFieldDelegate
extension RegistrationViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.setFocusedBorder(isActive: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.setFocusedBorder(isActive: false)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField === nameTextField {
            surnameTextField.becomeFirstResponder()
            return false
        }
        
        if textField === surnameTextField {
            textField.resignFirstResponder()

            if registerButton.isEnabled {
                registerButton.sendActions(for: .touchUpInside)
            }

            return false
        }

        return true
    }
}

// MARK: - PHPickerViewControllerDelegate
extension RegistrationViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.dismiss(animated: true)
            return
        }

        self.startLoadingState()

        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else {
                    Task { @MainActor [weak self] in
                        self?.stopLoadingState()
                    }
                    return
                }

                Task { @MainActor [weak self] in
                    await self?.interactor.openAvatarCrop(with: image)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension RegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)

        picker.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            guard let image else { return }

            self.startLoadingState()

            Task { @MainActor [weak self] in
                await self?.interactor.openAvatarCrop(with: image)
            }
        }
    }
}
