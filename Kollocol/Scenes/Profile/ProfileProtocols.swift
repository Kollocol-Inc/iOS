//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol ProfileInteractor {
    func logout() async
}

protocol ProfilePresenter {
    func presentLogoutConfirmation(onConfirm: @escaping @MainActor () -> Void) async
}
