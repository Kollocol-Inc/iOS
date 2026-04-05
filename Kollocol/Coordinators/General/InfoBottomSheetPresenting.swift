//
//  InfoBottomSheetPresenting.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 09.03.2026.
//

import UIKit

@MainActor
protocol InfoBottomSheetPresenting: AnyObject {
    var bottomSheetHostViewController: UIViewController? { get }
}

extension InfoBottomSheetPresenting {
    func showInfoBottomSheet(title: String, description: String, buttonTitle: String = "ОК") {
        showInfoBottomSheet(
            InfoBottomSheetContent(
                title: title,
                description: description,
                buttonTitle: buttonTitle
            )
        )
    }

    func showInfoBottomSheet(
        _ content: InfoBottomSheetContent,
        onAction: ((InfoBottomSheetActionIdentifier) -> Void)? = nil
    ) {
        guard let host = bottomSheetHostViewController else { return }

        let viewController = InfoBottomSheetViewController(
            content: content,
            onAction: onAction
        )
        viewController.modalPresentationStyle = .pageSheet
        viewController.loadViewIfNeeded()

        if let sheet = viewController.sheetPresentationController {
             if #available(iOS 16.0, *) {
                 let fitDetent = UISheetPresentationController.Detent.custom(
                     identifier: .init("info.bottom.sheet.fit")
                 ) { [weak viewController] context in
                     guard let viewController else {
                         return context.maximumDetentValue * 0.5
                     }

                     let preferredHeight = viewController.preferredContentSize.height
                     if preferredHeight > 0 {
                         return min(preferredHeight, context.maximumDetentValue)
                     }

                     return viewController.preferredSheetHeight(maximumDetentValue: context.maximumDetentValue)
                 }

                 sheet.detents = [fitDetent]
             } else {
                 sheet.detents = [.medium()]
             }
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.preferredCornerRadius = 24
        }

        host.present(viewController, animated: true)
    }

    func showQuizJoinConfirmationSheet(
        quizTitle: String,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        let normalizedQuizTitle = quizTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayQuizTitle = normalizedQuizTitle.isEmpty ? "квизу" : "\"\(normalizedQuizTitle)\""

        let content = InfoBottomSheetContent(
            title: "Подключение к квизу",
            description: "Вы уверены, что хотите подключиться к квизу \(displayQuizTitle)?",
            buttonsConfiguration: .double(
                left: InfoBottomSheetAction(
                    identifier: .cancel,
                    title: "Отмена",
                    style: .textSecondary
                ),
                right: InfoBottomSheetAction(
                    identifier: .confirm,
                    title: "Подключиться",
                    style: .accentPrimary
                )
            )
        )

        showInfoBottomSheet(content) { action in
            guard action == .confirm else { return }

            Task { @MainActor in
                onConfirm()
            }
        }
    }

    func showAsyncQuizStartConfirmationSheet(
        quizTitle: String?,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        let normalizedQuizTitle = quizTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description: String
        if normalizedQuizTitle.isEmpty {
            description = "Вы уверены, что хотите приступить к выполнению этого квиза?"
        } else {
            description = "Вы уверены, что хотите приступить к выполнению квиза \(normalizedQuizTitle)?"
        }

        let content = InfoBottomSheetContent(
            title: "Приступить к выполнению",
            description: description,
            buttonsConfiguration: .double(
                left: InfoBottomSheetAction(
                    identifier: .cancel,
                    title: "Отмена",
                    style: .textSecondary
                ),
                right: InfoBottomSheetAction(
                    identifier: .confirm,
                    title: "Приступить",
                    style: .accentPrimary
                )
            )
        )

        showInfoBottomSheet(content) { action in
            guard action == .confirm else { return }

            Task { @MainActor in
                onConfirm()
            }
        }
    }

    func showKickParticipantConfirmationSheet(
        participantName: String,
        onConfirm: @escaping @MainActor () -> Void
    ) {
        let normalizedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = normalizedName.isEmpty ? "этого участника" : normalizedName

        let content = InfoBottomSheetContent(
            title: "Выгнать участника",
            description: "Вы уверены, что хотите выгнать \(displayName)?",
            buttonsConfiguration: .double(
                left: InfoBottomSheetAction(
                    identifier: .cancel,
                    title: "Отмена",
                    style: .textSecondary
                ),
                right: InfoBottomSheetAction(
                    identifier: .confirm,
                    title: "Выгнать",
                    style: .backgroundRedSecondary
                )
            )
        )

        showInfoBottomSheet(content) { action in
            guard action == .confirm else { return }

            Task { @MainActor in
                onConfirm()
            }
        }
    }

    func showKickedFromQuizSheet(quizTitle: String?) {
        let normalizedQuizTitle = quizTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description: String
        if normalizedQuizTitle.isEmpty {
            description = "Вы были выгнаны из квиза"
        } else {
            description = "Вы были выгнаны из квиза \(normalizedQuizTitle)"
        }

        showInfoBottomSheet(
            title: "С прискорбием сообщаем...",
            description: description,
            buttonTitle: "ОК"
        )
    }

    func showSessionReplacedSheet() {
        showInfoBottomSheet(
            title: "С прискорбием сообщаем...",
            description: "Вы зашли в квиз с другого устройства",
            buttonTitle: "ОК"
        )
    }
}
