//
//  NotificationsAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import UIKit

enum NotificationsAssembly {
    @MainActor
    static func build(
        router: MainRouting,
        notificationsService: NotificationsService,
        groupService: GroupService
    ) -> UIViewController {
        let presenter = NotificationsRouter(router: router)
        let interactor = NotificationsLogic(
            presenter: presenter,
            notificationsService: notificationsService,
            groupService: groupService
        )
        let view = NotificationsViewController(interactor: interactor)
        presenter.view = view
        return view
    }
}
