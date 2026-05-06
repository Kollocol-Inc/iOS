//
//  MainLogic.swift
//  Kollocol
//
//  Created by Arseniy on 09.02.2026.
//

import UIKit

@MainActor
final class GroupsLogic: GroupsInteractor {
    // MARK: - Constants
    private let presenter: GroupsPresenter
    private let groupService: GroupService
    private let userService: UserService

    private enum EmptyStateText {
        static let noMatchingGroups = "groupsNoGroupsWithSuchName"
        static let noMemberGroups = "groupsNoMemberGroups"
        static let noOwnerGroups = "groupsNoOwnerGroups"
    }

    // MARK: - Properties
    private var allMemberGroups: [Group] = []
    private var allOwnerGroups: [Group] = []
    private var searchQuery = ""
    private var currentUserId: String?

    // MARK: - Lifecycle
    init(
        presenter: GroupsPresenter,
        groupService: GroupService,
        userService: UserService
    ) {
        self.presenter = presenter
        self.groupService = groupService
        self.userService = userService
    }

    // MARK: - Methods
    func fetchGroups() async {
        do {
            async let groupsReloadTask = reloadGroups()
            async let currentUserReloadTask = reloadCurrentUserIdSilently()

            try await groupsReloadTask
            await currentUserReloadTask
            await presentFilteredGroups()
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
        }
    }

    func handleSearchQueryChanged(_ query: String) {
        searchQuery = query
        Task {
            await presentFilteredGroups()
        }
    }

    func handleGroupTap(_ group: GroupsModels.GroupViewData, mode: GroupsModels.Mode) async {
        let normalizedGroupId = group.id?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let normalizedGroupId, normalizedGroupId.isEmpty == false else { return }

        let isCurrentUserOwner: Bool = {
            let normalizedOwnerId = group.ownerId?.trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedCurrentUserId = currentUserId?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let normalizedOwnerId, normalizedOwnerId.isEmpty == false,
               let normalizedCurrentUserId, normalizedCurrentUserId.isEmpty == false {
                return normalizedOwnerId == normalizedCurrentUserId
            }

            if allOwnerGroups.contains(where: { ownedGroup in
                ownedGroup.id?.trimmingCharacters(in: .whitespacesAndNewlines) == normalizedGroupId
            }) {
                return true
            }

            return mode == .owner
        }()

        await presenter.presentGroupPreview(
            GroupPreviewModels.InitialData(
                groupId: normalizedGroupId,
                title: group.title,
                subtitle: group.subtitle,
                avatarUrl: group.avatarUrl,
                ownerId: group.ownerId,
                isCurrentUserOwner: isCurrentUserOwner
            )
        )
    }

    func createGroup(
        name: String,
        description: String?,
        memberEmails: [String],
        avatarData: Data?
    ) async -> Bool {
        let safeName = String(name)
        let normalizedGroupName = safeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedGroupName.isEmpty == false else { return false }
        let normalizedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedEmails = memberEmails
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        do {
            var avatarUrl: String?
            if let avatarData {
                avatarUrl = try await groupService.uploadGroupAvatar(data: avatarData)
            }

            _ = try await groupService.createGroup(
                CreateGroupRequest(
                    avatarUrl: avatarUrl,
                    description: normalizedDescription?.isEmpty == false ? normalizedDescription : nil,
                    memberEmails: normalizedEmails.isEmpty ? nil : normalizedEmails,
                    name: normalizedGroupName
                )
            )
            try await reloadGroups()
            await presentFilteredGroups()
            return true
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
            return false
        }
    }

    // MARK: - Private Methods
    private func reloadGroups() async throws {
        async let memberGroupsTask = groupService.getGroups(filter: .my)
        async let ownerGroupsTask = groupService.getGroups(filter: .created)
        let (memberGroups, ownerGroups) = try await (memberGroupsTask, ownerGroupsTask)
        allMemberGroups = memberGroups
        allOwnerGroups = ownerGroups
    }

    private func reloadCurrentUserIdSilently() async {
        do {
            let userDTO = try await userService.getUserProfile()
            let user = userDTO.toDomain()
            let normalizedUserId = user.id?.trimmingCharacters(in: .whitespacesAndNewlines)
            currentUserId = normalizedUserId?.isEmpty == false ? normalizedUserId : nil
        } catch {
            currentUserId = nil
        }
    }

    private func presentFilteredGroups() async {
        let normalizedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        let memberGroups: [Group]
        let ownerGroups: [Group]
        let memberEmptyStateText: String?
        let ownerEmptyStateText: String?

        if normalizedQuery.isEmpty {
            memberGroups = allMemberGroups
            ownerGroups = allOwnerGroups
            memberEmptyStateText = memberGroups.isEmpty ? EmptyStateText.noMemberGroups.localized : nil
            ownerEmptyStateText = ownerGroups.isEmpty ? EmptyStateText.noOwnerGroups.localized : nil
        } else {
            memberGroups = allMemberGroups.filter {
                ($0.name?.localizedCaseInsensitiveContains(normalizedQuery) ?? false)
            }
            ownerGroups = allOwnerGroups.filter {
                ($0.name?.localizedCaseInsensitiveContains(normalizedQuery) ?? false)
            }
            memberEmptyStateText = memberGroups.isEmpty ? EmptyStateText.noMatchingGroups.localized : nil
            ownerEmptyStateText = ownerGroups.isEmpty ? EmptyStateText.noMatchingGroups.localized : nil
        }

        await presenter.presentGroups(
            memberGroups: memberGroups,
            ownerGroups: ownerGroups,
            memberEmptyStateText: memberEmptyStateText,
            ownerEmptyStateText: ownerEmptyStateText
        )
    }
}
