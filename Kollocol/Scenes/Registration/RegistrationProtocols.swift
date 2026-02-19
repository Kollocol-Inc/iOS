//
//  RegistrationProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol RegistrationInteractor: AvatarFlowInteracting {
    func register(name: String, surname: String, avatarData: Data?) async
}

protocol RegistrationPresenter {
    func presentSuccessfulRegister() async
    func presentRegisterError(_ error: UserServiceError) async

    // MARK: - Avatar
    func presentAvatarUploadError() async
    func presentAvatarCrop(image: UIImage, onFinish: @escaping @MainActor (UIImage?) -> Void) async
    func presentDeleteAvatarConfirmation(onConfirm: @escaping @MainActor () -> Void) async
}
