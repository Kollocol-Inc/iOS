//
//  VerifyCodeProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

protocol VerifyCodeInteractor {
    func verify(code: String, with email: String) async
}

protocol VerifyCodePresenter {
    func presentSuccessfulVerifying() async
    func presentVerifyingError(_ error: AuthServiceError) async
}
