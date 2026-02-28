//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

protocol MainInteractor {
    func fetchUserProfile() async
    func routeToProfileScreen() async
}

protocol MainPresenter {
    func presentUserProfile(_ user: UserDTO) async
    func presentError(_ error: UserServiceError) async
    func presentProfileScreen() async
}
