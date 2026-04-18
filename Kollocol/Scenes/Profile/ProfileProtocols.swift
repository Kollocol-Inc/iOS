//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol ProfileInteractor {
    func fetchUserProfile() async
    func fetchNotificationsSettings() async
    func fetchThemeOption() async
    func updateUserProfile(name: String, surname: String) async
    func uploadAvatar(data: Data) async -> Bool
    func deleteAvatar() async
    func updateNewQuizzesNotification(isEnabled: Bool) async
    func updateQuizResultsNotification(isEnabled: Bool) async
    func updateGroupInvitesNotification(isEnabled: Bool) async
    func updateDeadlineReminder(_ option: ProfileModels.DeadlineReminderOption) async
    func updateThemeOption(_ option: ProfileModels.ThemeOption) async
    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async
    func logout() async
}

protocol ProfilePresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentNotificationsSettings(_ settings: ProfileModels.NotificationsSettings) async
    func presentThemeOption(_ option: ProfileModels.ThemeOption) async
    func presentProfileUpdateError(_ error: UserServiceError) async
    func presentAvatarUploadError(_ error: UserServiceError) async
    func presentAvatarDeleteError(_ error: UserServiceError) async
    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async
    func presentServiceError(_ error: UserServiceError) async
    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async
}
