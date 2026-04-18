//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

final class ProfileLogic: ProfileInteractor {
    // MARK: - Constants
    private let presenter: ProfilePresenter
    private let userService: UserService
    private let sessionManager: SessionManager
    private let udService: UserDefaultsService

    // MARK: - Properties
    private var notificationsSettings = ProfileModels.NotificationsSettings.default

    // MARK: - Lifecycle
    init(
        presenter: ProfilePresenter,
        userService: UserService,
        sessionManager: SessionManager,
        udService: UserDefaultsService
    ) {
        self.presenter = presenter
        self.userService = userService
        self.sessionManager = sessionManager
        self.udService = udService
    }

    // MARK: - Methods
    func fetchUserProfile() async {
        do {
            let user = try await userService.getUserProfile()
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentServiceError(UserServiceError.wrap(error))
        }
    }

    func fetchNotificationsSettings() async {
        do {
            let settingsDTO = try await userService.getNotifications()
            let settings = ProfileModels.NotificationsSettings(dto: settingsDTO)
            notificationsSettings = settings
            await presenter.presentNotificationsSettings(settings)
        } catch {
            await presenter.presentServiceError(UserServiceError.wrap(error))
        }
    }

    func fetchThemeOption() async {
        let option = ProfileModels.ThemeOption(themePreference: udService.appThemePreference)
        await presenter.presentThemeOption(option)
    }

    func updateUserProfile(name: String, surname: String) async {
        do {
            let user = try await userService.updateUserProfile(name: name, surname: surname)
            await presenter.presentUserProfile(user)
        } catch {
            await presenter.presentProfileUpdateError(UserServiceError.wrap(error))
        }
    }

    func uploadAvatar(data: Data) async -> Bool {
        do {
            try await userService.uploadAvatar(data: data)
            return true
        } catch {
            await presenter.presentAvatarUploadError(UserServiceError.wrap(error))
            return false
        }
    }

    func deleteAvatar() async {
        do {
            try await userService.deleteAvatar()
        } catch {
            await presenter.presentAvatarDeleteError(UserServiceError.wrap(error))
        }
    }

    func updateNewQuizzesNotification(isEnabled: Bool) async {
        await updateNotificationsSettings { settings in
            settings.newQuizzes = isEnabled
        }
    }

    func updateQuizResultsNotification(isEnabled: Bool) async {
        await updateNotificationsSettings { settings in
            settings.quizResults = isEnabled
        }
    }

    func updateGroupInvitesNotification(isEnabled: Bool) async {
        await updateNotificationsSettings { settings in
            settings.groupInvites = isEnabled
        }
    }

    func updateDeadlineReminder(_ option: ProfileModels.DeadlineReminderOption) async {
        await updateNotificationsSettings { settings in
            settings.deadlineReminder = option
        }
    }

    func updateThemeOption(_ option: ProfileModels.ThemeOption) async {
        udService.appThemePreference = option.themePreference
        await presenter.presentThemeOption(option)
    }

    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async {
        await presenter.presentAvatarCrop(image: image, onFinish: onFinish)
    }

    func logout() async {
        await presenter.presentLogoutConfirmation { [weak self] in
            Task { [weak self] in
                await self?.performLogout()
            }
        }
    }

    // MARK: - Private Methods
    private func updateNotificationsSettings(
        _ mutate: (inout ProfileModels.NotificationsSettings) -> Void
    ) async {
        let previousSettings = notificationsSettings
        var updatedSettings = notificationsSettings
        mutate(&updatedSettings)

        notificationsSettings = updatedSettings
        do {
            let response = try await userService.updateNotifications(
                deadlineReminder: updatedSettings.deadlineReminder.rawValue,
                groupInvites: updatedSettings.groupInvites,
                newQuizzes: updatedSettings.newQuizzes,
                quizResults: updatedSettings.quizResults
            )
            let synchronizedSettings = ProfileModels.NotificationsSettings(dto: response)
            notificationsSettings = synchronizedSettings
            await presenter.presentNotificationsSettings(synchronizedSettings)
        } catch {
            notificationsSettings = previousSettings
            await presenter.presentNotificationsSettings(previousSettings)
            await presenter.presentServiceError(UserServiceError.wrap(error))
        }
    }

    private func performLogout() async {
        await sessionManager.forcedLogout()
    }
}
