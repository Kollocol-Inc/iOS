//
//  GroupPreviewAssembly.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import UIKit

enum GroupPreviewAssembly {
    @MainActor
    static func build(
        router: GroupsRouting,
        initialData: GroupPreviewModels.InitialData,
        groupService: GroupService,
        userService: UserService
    ) -> UIViewController {
        let presenter = GroupPreviewRouter(router: router)
        let interactor = GroupPreviewLogic(
            presenter: presenter,
            groupService: groupService,
            userService: userService,
            initialData: initialData
        )
        let view = GroupPreviewViewController(
            interactor: interactor,
            initialData: initialData
        )
        presenter.view = view
        return view
    }
}
