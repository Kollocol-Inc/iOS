//
//  MainProtocols.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
protocol GroupsInteractor {
    func fetchGroups() async
    func handleSearchQueryChanged(_ query: String)
    func handleGroupTap(_ group: GroupsModels.GroupViewData, mode: GroupsModels.Mode) async
    func createGroup(
        name: String,
        description: String?,
        memberEmails: [String],
        avatarData: Data?
    ) async -> Bool
}

@MainActor
protocol GroupsPresenter {
    func presentGroups(
        memberGroups: [Group],
        ownerGroups: [Group],
        memberEmptyStateText: String?,
        ownerEmptyStateText: String?
    ) async
    func presentServiceError(_ error: GroupServiceError) async
    func presentGroupPreview(_ initialData: GroupPreviewModels.InitialData) async
}
