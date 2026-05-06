//
//  MainAssembly.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

enum GroupsAssembly {
    @MainActor
    static func build(
        router: GroupsRouting,
        groupService: GroupService,
        userService: UserService
    ) -> UIViewController {
        let presenter = GroupsRouter(router: router)
        let interactor = GroupsLogic(
            presenter: presenter,
            groupService: groupService,
            userService: userService
        )
        let view = GroupsViewController(interactor: interactor)
        presenter.view = view
        
        return view
    }
}
