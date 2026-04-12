//
//  AvatarPickerController.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 19.02.2026.
//

import UIKit
import PhotosUI

@MainActor
final class AvatarPickerController: NSObject {
    // MARK: - Typealias
    typealias AvatarPayload = (image: UIImage?, data: Data?)

    // MARK: - UI Components
    private let avatarView: AvatarPickerView

    // MARK: - Constants
    private enum Constants {
        static let jpegQuality: CGFloat = 0.8
    }

    // MARK: - Properties
    private weak var presentingViewController: UIViewController?
    private weak var interactor: (any AvatarFlowInteracting)?

    private let onProcessingChanged: @MainActor (Bool) -> Void
    private let onAvatarChanged: @MainActor (AvatarPayload) -> Void
    private var isAvatarProcessing = false

    // MARK: - Lifecycle
    init(
        avatarView: AvatarPickerView,
        presentingViewController: UIViewController,
        interactor: any AvatarFlowInteracting,
        initialAvatar: UIImage? = nil,
        onProcessingChanged: @escaping @MainActor (Bool) -> Void,
        onAvatarChanged: @escaping @MainActor (AvatarPayload) -> Void
    ) {
        self.avatarView = avatarView
        self.presentingViewController = presentingViewController
        self.interactor = interactor
        self.onProcessingChanged = onProcessingChanged
        self.onAvatarChanged = onAvatarChanged
        super.init()

        avatarView.setAvatar(initialAvatar)
        updateMenu()
    }

    // MARK: - Methods
    func setAvatar(_ image: UIImage?) {
        avatarView.setAvatar(image)
        updateMenu()
    }

    // MARK: - Private Methods
    private func updateMenu() {
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

        if avatarView.hasAvatar() {
            let deleteAction = UIAction(
                title: "Удалить фото",
                image: trashImage,
                attributes: [.destructive]
            ) { [weak self] _ in
                self?.requestDeleteConfirmation()
            }
            actions.append(deleteAction)
        }

        avatarView.setMenu(UIMenu(title: "", children: actions))
    }

    private func requestDeleteConfirmation() {
        guard let interactor else { return }

        Task { @MainActor [weak self] in
            await interactor.presentAvatarDeleteConfirmation { [weak self] in
                guard let self else { return }
                self.setAvatar(nil)
                self.onAvatarChanged((image: nil, data: nil))
            }
        }
    }

    private func presentGalleryPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presentingViewController?.present(picker, animated: true)
    }

    private func presentCameraPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        presentingViewController?.present(picker, animated: true)
    }

    private func crop(image: UIImage) {
        guard let interactor else {
            endProcessingIfNeeded()
            return
        }

        Task { @MainActor [weak self] in
            await interactor.presentAvatarCrop(image: image) { [weak self] cropped in
                guard let self else { return }
                defer { self.endProcessingIfNeeded() }

                guard let cropped else { return }

                self.setAvatar(cropped)
                let data = cropped.jpegData(compressionQuality: Constants.jpegQuality)
                self.onAvatarChanged((image: cropped, data: data))
            }
        }
    }

    private func beginProcessingIfNeeded() {
        guard isAvatarProcessing == false else { return }
        isAvatarProcessing = true
        onProcessingChanged(true)
    }

    private func endProcessingIfNeeded() {
        guard isAvatarProcessing else { return }
        isAvatarProcessing = false
        onProcessingChanged(false)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension AvatarPickerController: PHPickerViewControllerDelegate {
    nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let result = results.first else {
                picker.dismiss(animated: true)
                return
            }
            guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
                picker.dismiss(animated: true)
                return
            }

            self.beginProcessingIfNeeded()
            picker.dismiss(animated: true)

            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard let image = object as? UIImage else {
                        self.endProcessingIfNeeded()
                        return
                    }
                    self.crop(image: image)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AvatarPickerController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    nonisolated func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        Task { @MainActor in
            picker.dismiss(animated: true)
        }
    }

    nonisolated func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)

        Task { @MainActor [weak self] in
            guard let self, let image else {
                picker.dismiss(animated: true)
                return
            }
            self.beginProcessingIfNeeded()
            picker.dismiss(animated: true)
            self.crop(image: image)
        }
    }
}
