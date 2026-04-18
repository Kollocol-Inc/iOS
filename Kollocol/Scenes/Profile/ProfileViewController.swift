//
//  MainViewController.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit
import Kingfisher
import ShimmerView
import PhotosUI
import AVFoundation

final class ProfileViewController: UIViewController {
    // MARK: - Typealias
    private final class ProfileHeaderShimmerSyncView: UIView, ShimmerSyncTarget {
        // MARK: - Properties
        var style: ShimmerViewStyle = .default
        var effectBeginTime: CFTimeInterval = 0
    }

    // MARK: - UI Components
    private let profileInfoContainerView: ProfileHeaderShimmerSyncView = {
        let view = ProfileHeaderShimmerSyncView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 28
        view.layer.cornerCurve = .continuous
        view.clipsToBounds = true
        return view
    }()

    private let profileInfoGlassBackgroundView: UIVisualEffectView = {
        if #available(iOS 26.0, *) {
            return UIVisualEffectView(effect: UIGlassEffect(style: .regular))
        } else {
            return UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
    }()

    private let profileContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 12
        return stack
    }()

    private let profileMenuButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "avatarPlaceholder"))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 22.5
        imageView.layer.borderWidth = 1.5
        imageView.clipsToBounds = true
        imageView.backgroundColor = .backgroundSecondary
        return imageView
    }()

    private let avatarShimmerView = ShimmerView()

    private let profileTextStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 0
        return stack
    }()

    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .textPrimary
        label.text = " "
        label.alpha = 0
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .textSecondary
        label.text = " "
        label.alpha = 0
        return label
    }()

    private let fullNameShimmerView = ShimmerView()
    private let emailShimmerView = ShimmerView()

    private let tableBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .backgroundSecondary
        view.layer.cornerRadius = 28
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowRadius = 9
        view.layer.shadowOpacity = 0.1
        return view
    }()

    private let tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.layer.cornerRadius = 28
        table.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        table.clipsToBounds = true
        return table
    }()

    // MARK: - Constants
    private enum UIConstants {
        static let profileInfoTopInset: CGFloat = 10
        static let profileInfoHorizontalInset: CGFloat = 24
        static let profileInfoHeight: CGFloat = 80
        static let profileInfoToTableSpacing: CGFloat = 16
        static let profileInfoInnerInset: CGFloat = 16
        static let avatarSize: CGFloat = 45
        static let fullNameShimmerWidth: CGFloat = 148
        static let fullNameShimmerHeight: CGFloat = 16
        static let emailShimmerWidth: CGFloat = 126
        static let emailShimmerHeight: CGFloat = 12
        static let avatarJPEGQuality: CGFloat = 0.8

        static let cameraAccessDeniedSheetTitle = "Внимание"
        static let cameraAccessDeniedSheetDescription = "У приложения нет доступа к камере. Перейдите в настройки и выдайте соответствующие разрешения, после чего вернитесь обратно и попробуйте снова"
        static let themeTransitionDuration: TimeInterval = 0.4
    }

    // MARK: - Properties
    private var interactor: ProfileInteractor
    private var isProfileShimmerAnimating = false
    private var currentFirstName = ""
    private var currentLastName = ""
    private var hasAvatar = false
    private var notificationsSettings = ProfileModels.NotificationsSettings.default
    private var selectedThemeOption: ProfileModels.ThemeOption = .system

    private let rows: [ProfileModels.Row] = [
        .header("Уведомления"),
        .notificationToggle(type: .newQuiz),
        .divider,
        .notificationToggle(type: .quizResults),
        .divider,
        .notificationToggle(type: .groupInvites),
        .divider,
        .notificationDeadline,
        .header("Настройки"),
        .theme
    ]

    private lazy var profileShimmerViews: [ShimmerView] = [
        avatarShimmerView,
        fullNameShimmerView,
        emailShimmerView
    ]

    // MARK: - Lifecycle
    init(interactor: ProfileInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()

        Task {
            async let profileTask: Void = interactor.fetchUserProfile()
            async let notificationsTask: Void = interactor.fetchNotificationsSettings()
            async let themeTask: Void = interactor.fetchThemeOption()
            _ = await (profileTask, notificationsTask, themeTask)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let previousTraitCollection else { return }
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        updateAvatarBorderColor(for: traitCollection)
        guard isProfileShimmerAnimating else { return }

        let shimmerStyle = makeProfileShimmerStyle(for: effectiveShimmerTraitCollection)
        profileInfoContainerView.style = shimmerStyle
        profileShimmerViews.forEach { $0.apply(style: shimmerStyle) }

    }

    // MARK: - Methods
    @MainActor
    func displayUserProfile(avatarUrl: String?, firstName: String, lastName: String, email: String) {
        stopProfileLoadingShimmer()

        currentFirstName = firstName
        currentLastName = lastName
        hasAvatar = (avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)

        let fullName = makeFullName(firstName: firstName, lastName: lastName)
        fullNameLabel.text = fullName.isEmpty ? " " : fullName
        emailLabel.text = email
        avatarImageView.setImage(url: avatarUrl, placeholder: UIImage(named: "avatarPlaceholder"))
        configureProfileMenu()
    }

    @MainActor
    func displayNotificationsSettings(_ settings: ProfileModels.NotificationsSettings) {
        let previousSettings = notificationsSettings
        notificationsSettings = settings
        guard previousSettings != settings else { return }
        tableView.reloadData()
    }

    @MainActor
    func displayThemeOption(_ option: ProfileModels.ThemeOption) {
        guard selectedThemeOption != option else { return }
        selectedThemeOption = option
        tableView.reloadData()
    }

    // MARK: - Private Methods
    private func configureUI() {
        view.setPrimaryBackground()
        configureConstraints()
        configureNavbar()
        configureProfileMenu()
        configureTableView()
        configureProfileInfoGlassBackground()
        configureProfileShimmerShape()
        updateAvatarBorderColor(for: traitCollection)
        startProfileLoadingShimmer()
    }

    private func configureNavbar() {
        // title
        var title = AttributedString("Профиль")
        title.foregroundColor = .textSecondary
        title.font = .systemFont(ofSize: 20, weight: .bold)
        navigationItem.attributedTitle = title

        // right button
        let showPopupAndLogoutAction = UIAction { [weak self] _ in
            Task { [weak self] in
                await self?.interactor.logout()
            }
        }

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(
                    systemName: "door.right.hand.open"
                )?.withTintColor(
                    .backgroundRedPrimary,
                    renderingMode: .alwaysOriginal
                ),
                primaryAction: showPopupAndLogoutAction
            )
        ]

        // left button
        navigationItem.backBarButtonItem = UIBarButtonItem(
            image: UIImage(
                systemName: "chevron.backward"
            )?.withTintColor(
                .textSecondary,
                renderingMode: .alwaysOriginal
            )
        )
    }

    private func configureConstraints() {
        view.addSubview(profileInfoContainerView)
        profileInfoContainerView.pinTop(to: view.safeAreaLayoutGuide.topAnchor, UIConstants.profileInfoTopInset)
        profileInfoContainerView.pinLeft(to: view.safeAreaLayoutGuide.leadingAnchor, UIConstants.profileInfoHorizontalInset)
        profileInfoContainerView.pinRight(to: view.safeAreaLayoutGuide.trailingAnchor, UIConstants.profileInfoHorizontalInset)
        profileInfoContainerView.setHeight(UIConstants.profileInfoHeight)

        profileInfoContainerView.addSubview(profileInfoGlassBackgroundView)
        profileInfoGlassBackgroundView.pin(to: profileInfoContainerView)

        profileInfoContainerView.addSubview(profileContentStackView)
        profileContentStackView.pinLeft(to: profileInfoContainerView.leadingAnchor, UIConstants.profileInfoInnerInset)
        profileContentStackView.pinRight(to: profileInfoContainerView.trailingAnchor, UIConstants.profileInfoInnerInset, .lsOE)
        profileContentStackView.pinCenterY(to: profileInfoContainerView.centerYAnchor)

        profileContentStackView.addArrangedSubview(avatarImageView)
        avatarImageView.setWidth(UIConstants.avatarSize)
        avatarImageView.setHeight(UIConstants.avatarSize)

        profileContentStackView.addArrangedSubview(profileTextStackView)
        profileTextStackView.addArrangedSubview(fullNameLabel)
        profileTextStackView.addArrangedSubview(emailLabel)

        profileInfoContainerView.addSubview(profileMenuButton)
        profileMenuButton.pin(to: profileInfoContainerView)

        avatarImageView.addSubview(avatarShimmerView)
        avatarShimmerView.pin(to: avatarImageView)

        profileTextStackView.addSubview(fullNameShimmerView)
        fullNameShimmerView.pinLeft(to: profileTextStackView.leadingAnchor)
        fullNameShimmerView.pinCenterY(to: fullNameLabel.centerYAnchor)
        fullNameShimmerView.setWidth(UIConstants.fullNameShimmerWidth)
        fullNameShimmerView.setHeight(UIConstants.fullNameShimmerHeight)

        profileTextStackView.addSubview(emailShimmerView)
        emailShimmerView.pinLeft(to: profileTextStackView.leadingAnchor)
        emailShimmerView.pinCenterY(to: emailLabel.centerYAnchor)
        emailShimmerView.setWidth(UIConstants.emailShimmerWidth)
        emailShimmerView.setHeight(UIConstants.emailShimmerHeight)

        view.addSubview(tableBackgroundView)
        tableBackgroundView.pinHorizontal(to: view)
        tableBackgroundView.pinBottom(to: view.bottomAnchor)
        tableBackgroundView.pinTop(to: profileInfoContainerView.bottomAnchor, UIConstants.profileInfoToTableSpacing)

        view.addSubview(tableView)
        tableView.pin(to: tableBackgroundView)
    }

    private func configureTableView() {
        tableView.register(
            ProfileHeaderTableViewCell.self,
            forCellReuseIdentifier: ProfileHeaderTableViewCell.reuseIdentifier
        )
        tableView.register(
            ProfileNotificationToggleTableViewCell.self,
            forCellReuseIdentifier: ProfileNotificationToggleTableViewCell.reuseIdentifier
        )
        tableView.register(
            ProfileMenuSettingTableViewCell.self,
            forCellReuseIdentifier: ProfileMenuSettingTableViewCell.reuseIdentifier
        )
        tableView.register(
            DividerTableViewCell.self,
            forCellReuseIdentifier: DividerTableViewCell.reuseIdentifier
        )
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }

    private func configureProfileShimmerShape() {
        avatarShimmerView.layer.cornerRadius = UIConstants.avatarSize / 2
        avatarShimmerView.layer.masksToBounds = true

        fullNameShimmerView.layer.cornerRadius = UIConstants.fullNameShimmerHeight / 2
        fullNameShimmerView.layer.masksToBounds = true

        emailShimmerView.layer.cornerRadius = UIConstants.emailShimmerHeight / 2
        emailShimmerView.layer.masksToBounds = true
    }

    private func configureProfileInfoGlassBackground() {
        profileInfoGlassBackgroundView.backgroundColor = .clear
        profileInfoGlassBackgroundView.clipsToBounds = true
        profileInfoGlassBackgroundView.layer.cornerRadius = 28
        profileInfoGlassBackgroundView.layer.cornerCurve = .continuous
    }

    private func configureProfileMenu() {
        let editNameAction = UIAction(
            title: "Изменить имя или фамилию",
            image: UIImage(systemName: "pencil")
        ) { [weak self] _ in
            self?.presentProfileNameUpdateAlert()
        }

        let galleryAction = UIAction(
            title: "Галерея",
            image: UIImage(systemName: "photo.on.rectangle.angled.fill")
        ) { [weak self] _ in
            self?.presentGalleryPicker()
        }

        let cameraAction = UIAction(
            title: "Сделать фото",
            image: UIImage(systemName: "camera.fill")
        ) { [weak self] _ in
            self?.presentCameraPicker()
        }

        var profilePhotoActions: [UIAction] = [
            galleryAction,
            cameraAction
        ]
        if hasAvatar {
            let deletePhotoAction = UIAction(
                title: "Удалить фото",
                image: UIImage(systemName: "trash.fill"),
                attributes: [.destructive]
            ) { [weak self] _ in
                self?.deleteAvatar()
            }
            profilePhotoActions.append(deletePhotoAction)
        }

        let profilePhotoSection = UIMenu(
            title: "Фото профиля",
            options: .displayInline,
            children: profilePhotoActions
        )

        profileMenuButton.menu = UIMenu(
            options: .displayInline,
            children: [
                editNameAction,
                profilePhotoSection
            ]
        )
    }

    private func presentProfileNameUpdateAlert() {
        let alert = UIAlertController(
            title: "Изменить имя или фамилию",
            message: nil,
            preferredStyle: .alert
        )

        alert.addTextField { [weak self] textField in
            textField.placeholder = "Имя"
            textField.autocapitalizationType = .words
            textField.text = self?.currentFirstName
        }

        alert.addTextField { [weak self] textField in
            textField.placeholder = "Фамилия"
            textField.autocapitalizationType = .words
            textField.text = self?.currentLastName
        }

        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Обновить", style: .default) { [weak self, weak alert] _ in
            guard let self,
                  let textFields = alert?.textFields,
                  textFields.count == 2
            else {
                return
            }

            let enteredName = textFields[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let enteredSurname = textFields[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let name = enteredName.isEmpty ? self.currentFirstName : enteredName
            let surname = enteredSurname.isEmpty ? self.currentLastName : enteredSurname
            guard name.isEmpty == false, surname.isEmpty == false else { return }

            Task { [weak self] in
                await self?.interactor.updateUserProfile(name: name, surname: surname)
            }
        })

        present(alert, animated: true)
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
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch authorizationStatus {
        case .authorized:
            presentCameraPickerController()

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if isGranted {
                        self.presentCameraPickerController()
                    } else {
                        self.presentCameraAccessDeniedSheet()
                    }
                }
            }

        case .restricted, .denied:
            presentCameraAccessDeniedSheet()

        @unknown default:
            presentCameraAccessDeniedSheet()
        }
    }

    private func presentCameraPickerController() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        present(picker, animated: true)
    }

    private func deleteAvatar() {
        guard hasAvatar else { return }
        hasAvatar = false
        avatarImageView.image = UIImage(named: "avatarPlaceholder")
        configureProfileMenu()

        Task { [weak self] in
            await self?.interactor.deleteAvatar()
        }
    }

    private func presentCameraAccessDeniedSheet() {
        showInfoBottomSheet(
            title: UIConstants.cameraAccessDeniedSheetTitle,
            description: UIConstants.cameraAccessDeniedSheetDescription,
            buttonTitle: "ОК"
        )
    }

    private func handlePickedImage(_ image: UIImage) {
        Task { [weak self] in
            await self?.interactor.presentAvatarCrop(image: image) { [weak self] croppedImage in
                guard let self, let croppedImage else { return }

                self.hasAvatar = true
                self.avatarImageView.image = croppedImage
                self.configureProfileMenu()
                guard let imageData = croppedImage.jpegData(compressionQuality: UIConstants.avatarJPEGQuality) else {
                    return
                }

                Task { [weak self] in
                    guard let self else { return }
                    let isUploadSuccessful = await self.interactor.uploadAvatar(data: imageData)
                    guard isUploadSuccessful else { return }
                    await self.clearKingfisherCache()
                }
            }
        }
    }

    private func clearKingfisherCache() async {
        let imageCache = ImageCache.default
        imageCache.clearMemoryCache()
        await withCheckedContinuation { continuation in
            imageCache.clearDiskCache {
                continuation.resume()
            }
        }
    }

    private func makeFullName(firstName: String, lastName: String) -> String {
        [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
            .joined(separator: " ")
    }

    private func deadlineOptions() -> [ProfileMenuSettingTableViewCell.Option] {
        ProfileModels.DeadlineReminderOption.allCases.map { option in
            ProfileMenuSettingTableViewCell.Option(
                id: option.rawValue,
                title: option.title
            )
        }
    }

    private func themeOptions() -> [ProfileMenuSettingTableViewCell.Option] {
        ProfileModels.ThemeOption.allCases.map { option in
            ProfileMenuSettingTableViewCell.Option(
                id: option.rawValue,
                title: option.title
            )
        }
    }

    private func applyTheme(_ option: ProfileModels.ThemeOption) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach { window in
                UIView.transition(
                    with: window,
                    duration: UIConstants.themeTransitionDuration,
                    options: [.transitionCrossDissolve, .allowAnimatedContent]
                ) {
                    window.overrideUserInterfaceStyle = option.interfaceStyle
                    window.layoutIfNeeded()
                }
            }
    }

    private func handleNotificationToggleChange(
        _ type: ProfileModels.NotificationToggleType,
        isEnabled: Bool
    ) {
        switch type {
        case .newQuiz:
            notificationsSettings.newQuizzes = isEnabled
            Task { [weak self] in
                await self?.interactor.updateNewQuizzesNotification(isEnabled: isEnabled)
            }

        case .quizResults:
            notificationsSettings.quizResults = isEnabled
            Task { [weak self] in
                await self?.interactor.updateQuizResultsNotification(isEnabled: isEnabled)
            }

        case .groupInvites:
            notificationsSettings.groupInvites = isEnabled
            Task { [weak self] in
                await self?.interactor.updateGroupInvitesNotification(isEnabled: isEnabled)
            }
        }
    }

    private func handleDeadlineReminderChange(_ option: ProfileModels.DeadlineReminderOption) {
        guard notificationsSettings.deadlineReminder != option else { return }
        notificationsSettings.deadlineReminder = option
        tableView.reloadData()

        Task { [weak self] in
            await self?.interactor.updateDeadlineReminder(option)
        }
    }

    private func handleThemeChange(_ option: ProfileModels.ThemeOption) {
        guard selectedThemeOption != option else { return }
        selectedThemeOption = option
        tableView.reloadData()
        applyTheme(option)

        Task { [weak self] in
            await self?.interactor.updateThemeOption(option)
        }
    }

    private var effectiveShimmerTraitCollection: UITraitCollection {
        view.window?.traitCollection ?? traitCollection
    }

    private func startProfileLoadingShimmer() {
        isProfileShimmerAnimating = true
        let shimmerStyle = makeProfileShimmerStyle(for: effectiveShimmerTraitCollection)
        profileInfoContainerView.style = shimmerStyle
        profileInfoContainerView.effectBeginTime = CACurrentMediaTime()

        fullNameLabel.alpha = 0
        emailLabel.alpha = 0

        profileShimmerViews.forEach {
            $0.isHidden = false
            $0.apply(style: shimmerStyle)
            $0.startAnimating()
        }
    }

    private func stopProfileLoadingShimmer() {
        isProfileShimmerAnimating = false

        profileShimmerViews.forEach {
            $0.stopAnimating()
            $0.isHidden = true
        }

        fullNameLabel.alpha = 1
        emailLabel.alpha = 1
    }

    private func makeProfileShimmerStyle(for traitCollection: UITraitCollection) -> ShimmerViewStyle {
        ShimmerViewStyle(
            baseColor: UIColor.backgroundCardPrimary.resolvedColor(with: traitCollection),
            highlightColor: UIColor.backgroundPrimary.resolvedColor(with: traitCollection),
            duration: 1.2,
            interval: 0.4,
            effectSpan: .points(120),
            effectAngle: 0 * CGFloat.pi
        )
    }

    private func updateAvatarBorderColor(for traitCollection: UITraitCollection) {
        avatarImageView.layer.borderColor = UIColor.accentPrimary.resolvedColor(with: traitCollection).cgColor
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard let result = results.first else {
            picker.dismiss(animated: true)
            return
        }

        guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else {
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }

                Task { @MainActor [weak self] in
                    self?.handlePickedImage(image)
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        guard let image else {
            picker.dismiss(animated: true)
            return
        }

        picker.dismiss(animated: true) { [weak self] in
            self?.handlePickedImage(image)
        }
    }
}

// MARK: - UITableViewDataSource
extension ProfileViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case .header(let text):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ProfileHeaderTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? ProfileHeaderTableViewCell else {
                return UITableViewCell()
            }

            cell.configure(text: text)
            return cell

        case .notificationToggle(let type):
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ProfileNotificationToggleTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? ProfileNotificationToggleTableViewCell else {
                return UITableViewCell()
            }

            let isOn: Bool
            switch type {
            case .newQuiz:
                isOn = notificationsSettings.newQuizzes
            case .quizResults:
                isOn = notificationsSettings.quizResults
            case .groupInvites:
                isOn = notificationsSettings.groupInvites
            }

            cell.configure(title: type.title, isOn: isOn)
            cell.onToggleChanged = { [weak self] isEnabled in
                self?.handleNotificationToggleChange(type, isEnabled: isEnabled)
            }
            return cell

        case .divider:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: DividerTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? DividerTableViewCell else {
                return UITableViewCell()
            }
            return cell

        case .notificationDeadline:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ProfileMenuSettingTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? ProfileMenuSettingTableViewCell else {
                return UITableViewCell()
            }

            let selected = notificationsSettings.deadlineReminder
            cell.configure(
                title: "Дедлайн",
                options: deadlineOptions(),
                selectedOptionID: selected.rawValue
            )
            cell.onOptionSelected = { [weak self] selectedID in
                guard let option = ProfileModels.DeadlineReminderOption(rawValue: selectedID) else { return }
                self?.handleDeadlineReminderChange(option)
            }
            return cell

        case .theme:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: ProfileMenuSettingTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? ProfileMenuSettingTableViewCell else {
                return UITableViewCell()
            }

            let selected = selectedThemeOption
            cell.configure(
                title: "Тема",
                options: themeOptions(),
                selectedOptionID: selected.rawValue
            )
            cell.onOptionSelected = { [weak self] selectedID in
                guard let option = ProfileModels.ThemeOption(rawValue: selectedID) else { return }
                self?.handleThemeChange(option)
            }
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension ProfileViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .divider:
            return 1
        default:
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch rows[indexPath.row] {
        case .divider:
            return 1
        default:
            return 44
        }
    }
}

// MARK: - InfoBottomSheetPresenting
extension ProfileViewController: InfoBottomSheetPresenting {
    var bottomSheetHostViewController: UIViewController? {
        self
    }
}
