//
//  MainRouter.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class GroupsRouter: GroupsPresenter, ServiceErrorHandling {
    // MARK: - Properties
    weak var view: GroupsViewController?

    private let router: GroupsRouting
    var errorDisplayer: any ErrorMessageDisplaying { router }

    // MARK: - Lifecycle
    init(router: GroupsRouting) {
        self.router = router
    }

    // MARK: - Methods
    func presentGroups(
        memberGroups: [Group],
        ownerGroups: [Group],
        memberEmptyStateText: String?,
        ownerEmptyStateText: String?
    ) async {
        await view?.displayGroups(
            memberGroups: memberGroups.map { $0.toViewData() },
            ownerGroups: ownerGroups.map { $0.toViewData() },
            memberEmptyStateText: memberEmptyStateText,
            ownerEmptyStateText: ownerEmptyStateText
        )
    }

    func presentServiceError(_ error: GroupServiceError) async {
        await presentServiceError(error, useCase: .generic)
    }

    func presentGroupPreview(_ initialData: GroupPreviewModels.InitialData) async {
        await router.routeToGroupPreview(initialData: initialData)
    }
}

// MARK: - Group -> GroupViewData
private extension Group {
    func toViewData() -> GroupsModels.GroupViewData {
        GroupsModels.GroupViewData(
            id: id,
            title: name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? (name ?? "")
            : "untitled".localized,
            subtitle: description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? description
            : nil,
            ownerId: ownerId,
            memberCount: memberCount ?? 0,
            pendingInvitesCount: pendingInvitesCount ?? 0,
            avatarUrl: avatarUrl
        )
    }
}
