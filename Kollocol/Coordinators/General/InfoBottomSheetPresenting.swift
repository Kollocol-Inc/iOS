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

    func showInfoBottomSheet(_ content: InfoBottomSheetContent) {
        guard let host = bottomSheetHostViewController else { return }

        let viewController = InfoBottomSheetViewController(content: content)
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
}
