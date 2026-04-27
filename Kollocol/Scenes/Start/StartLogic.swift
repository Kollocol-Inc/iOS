//
//  StartInteractor.swift
//  Kollocol
//
//  Created by Arseniy on 01.02.2026.
//

import UIKit

actor StartLogic: StartInteractor {
    // MARK: - Constants
    private let presenter: StartPresenter
    private let authService: AuthService
    private let udService: UserDefaultsService
    
    // MARK: - Lifecycle
    init(
        presenter: StartPresenter,
        authService: AuthService,
        udService: UserDefaultsService
    ) {
        self.presenter = presenter
        self.authService = authService
        self.udService = udService
    }
    
    // MARK: - Methods
    func login(with email: String) async {
        do {
            try await authService.login(using: email)
            
            await presenter.presentLoginSuccess(email: email)
        } catch {
            await presenter.presentLoginError(AuthServiceError.wrap(error))
        }
    }

    func fetchLanguageOption() async {
        let option = StartModels.LanguageOption(languagePreference: udService.appLanguagePreference)
        await presenter.presentLanguageOption(option)
    }

    func updateLanguageOption(_ option: StartModels.LanguageOption) async {
        udService.appLanguagePreference = option.languagePreference
        await presenter.presentLanguageOption(option)
    }
}
