//
//  RegistrationProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol RegistrationInteractor {
    func register(name: String, surname: String) async

    // MARK: - Avatar
    func openAvatarCrop(with image: UIImage) async
    func storeAvatar(image: UIImage) async -> UIImage
    func clearAvatar() async
    func requestDeleteAvatarConfirmation() async
}

protocol RegistrationPresenter {
    func presentSuccessfulRegister() async
    func presentRegisterError(_ error: UserServiceError) async

    // MARK: - Avatar
    func presentAvatarCrop(image: UIImage) async
    func presentDeleteAvatarConfirmation() async
}
