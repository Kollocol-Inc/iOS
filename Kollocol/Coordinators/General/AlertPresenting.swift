//
//  AlertPresenting.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 15.02.2026.
//

import UIKit

// MARK: - AlertPresenting
@MainActor
protocol AlertPresenting: AnyObject {
    func presentAlert(_ alert: UIAlertController)
}

// MARK: - Implementation
extension AlertPresenting {
    func showAlert(
        title: String,
        message: String,
        okTitle: String = "ОК"
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okTitle, style: .default))
        presentAlert(alert)
    }

    func showConfirmationAlert(
        title: String,
        message: String,
        cancelTitle: String = "Отмена",
        confirmTitle: String,
        confirmStyle: UIAlertAction.Style = .destructive,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: confirmStyle) { _ in
            onConfirm()
        })
        presentAlert(alert)
    }
}

// MARK: - ErrorMessageDisplaying
@MainActor
protocol ErrorMessageDisplaying: AnyObject {
    func showError(title: String, message: String)
}

// MARK: - UserFacingError
protocol UserFacingError: Error {
    var userMessage: String { get }
}

extension AuthServiceError: UserFacingError {
    var userMessage: String {
        switch self {
        case .badRequest:
            return "Ошибка на стороне клиента"
        case .tooManyRequests:
            return "Слишком много попыток. Попробуйте еще раз через пару минут"
        case .offline:
            return "Нет интернета"
        case .server:
            return "Ошибка на стороне сервера. Идем будить девопса..."
        case .unauthorized:
            return "Ошибка авторизации. Выполните вход снова"
        default:
            return "Что-то пошло не так"
        }
    }
}

extension UserServiceError: UserFacingError {
    var userMessage: String {
        switch self {
        case .badRequest:
            return "Ошибка на стороне клиента"
        case .tooManyRequests:
            return "Слишком много попыток. Попробуйте еще раз через пару минут"
        case .offline:
            return "Нет интернета"
        case .server:
            return "Ошибка на стороне сервера. Идем будить девопса..."
        case .unauthorized:
            return "Ошибка авторизации. Выполните вход снова"
        default:
            return "Что-то пошло не так"
        }
    }
}

extension QuizServiceError: UserFacingError {
    var userMessage: String {
        switch self {
        case .badRequest:
            return "Ошибка на стороне клиента"
        case .tooManyRequests:
            return "Слишком много попыток. Попробуйте еще раз через пару минут"
        case .offline:
            return "Нет интернета"
        case .server:
            return "Ошибка на стороне сервера. Идем будить девопса..."
        case .unauthorized:
            return "Ошибка авторизации. Выполните вход снова"
        default:
            return "Что-то пошло не так"
        }
    }
}

extension QuizParticipationServiceError: UserFacingError {
    var userMessage: String {
        switch self {
        case .invalidCode:
            return "Такой код не существует или Вы ввели код неверно. Попробуйте еще раз"
        case .offline:
            return "Нет интернета"
        case .unauthorized:
            return "Ошибка авторизации. Выполните вход снова"
        case .connectionClosed:
            return "Соединение с квизом разорвано"
        case .connectionTimeout:
            return "Не удалось подключиться к квизу. Попробуйте еще раз"
        case .notConnected:
            return "Нет активного подключения к квизу"
        case .invalidConfiguration:
            return "Ошибка конфигурации websocket. Обратитесь к разработчику"
        case .encodingFailed:
            return "Не удалось отправить данные на сервер"
        case .unknown:
            return "Что-то пошло не так"
        }
    }
}

// MARK: - ServiceErrorHandling
enum ServiceErrorUseCase {
    case generic
    case registrationSubmit
    case avatarUpload
    case joinQuiz
}

@MainActor
protocol ServiceErrorHandling: AnyObject {
    var errorDisplayer: any ErrorMessageDisplaying { get }
    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String?
}

extension ServiceErrorHandling {
    func overrideMessage(for error: Error, useCase: ServiceErrorUseCase) -> String? {
        nil
    }

    func presentServiceError(
        _ error: Error,
        useCase: ServiceErrorUseCase = .generic,
        title: String = "Ошибка"
    ) async {
        let message = overrideMessage(for: error, useCase: useCase)
            ?? (error as? any UserFacingError)?.userMessage
            ?? "Что-то пошло не так"

        errorDisplayer.showError(title: title, message: message)
    }
}
