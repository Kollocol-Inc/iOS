//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol ProfileInteractor {
    func fetchUserProfile() async
    func logout() async
}

protocol ProfilePresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentServiceError(_ error: UserServiceError) async
    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async
}
