//
//  VerifyCodeProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 08.02.2026.
//

import UIKit

protocol VerifyCodeInteractor {
    func verify(code: String, with email: String) async
    func resendCode(to email: String) async
}

protocol VerifyCodePresenter {
    func presentSuccessfulVerifying(isRegistered: Bool) async
    func presentVerifyingError(_ error: AuthServiceError) async
    func presentResendCodeError(_ error: AuthServiceError) async
}
