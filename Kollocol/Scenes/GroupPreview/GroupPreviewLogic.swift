//
//  GroupPreviewLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import Foundation

@MainActor
final class GroupPreviewLogic: GroupPreviewInteractor {
    // MARK: - Properties
    private let presenter: GroupPreviewPresenter
    private let groupService: GroupService
    private let userService: UserService

    private var groupData: GroupPreviewModels.ViewData

    // MARK: - Lifecycle
    init(
        presenter: GroupPreviewPresenter,
        groupService: GroupService,
        userService: UserService,
        initialData: GroupPreviewModels.InitialData
    ) {
        self.presenter = presenter
        self.groupService = groupService
        self.userService = userService
        self.groupData = GroupPreviewModels.ViewData(
            groupId: initialData.groupId,
            title: initialData.title,
            subtitle: initialData.subtitle,
            avatarUrl: initialData.avatarUrl,
            ownerId: initialData.ownerId,
            isCurrentUserOwner: initialData.isCurrentUserOwner
        )
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        await presenter.presentGroup(groupData)

        do {
            try await reloadGroupDataAndParticipants()
        } catch {
            await presenter.presentParticipants(
                GroupPreviewModels.ParticipantsViewData(
                    members: [],
                    invitedMembers: []
                )
            )
            await presenter.presentServiceError(GroupServiceError.wrap(error))
        }
    }

    func handleEditGroup(_ request: GroupPreviewModels.EditGroupRequest) async -> Bool {
        let normalizedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedName.isEmpty == false else { return false }

        let normalizedDescription = request.description?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let avatarUrl: String?
            switch request.avatarAction {
            case .unchanged:
                avatarUrl = nil
            case .remove:
                avatarUrl = ""
            case .update(let data):
                avatarUrl = try await groupService.uploadGroupAvatar(data: data)
            }

            let updatedGroup = try await groupService.updateGroup(
                by: groupData.groupId,
                UpdateGroupRequest(
                    avatarUrl: avatarUrl,
                    description: normalizedDescription?.isEmpty == false ? normalizedDescription : nil,
                    name: normalizedName
                )
            )

            let updatedTitle = updatedGroup.normalizedName ?? groupData.title
            let updatedSubtitle = updatedGroup.normalizedDescription
            let updatedAvatarUrl = updatedGroup.normalizedAvatarUrl

            groupData = GroupPreviewModels.ViewData(
                groupId: groupData.groupId,
                title: updatedTitle,
                subtitle: updatedSubtitle,
                avatarUrl: updatedAvatarUrl,
                ownerId: updatedGroup.ownerId ?? groupData.ownerId,
                isCurrentUserOwner: groupData.isCurrentUserOwner
            )

            await presenter.presentGroup(groupData)
            return true
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
            return false
        }
    }

    func handleInviteMembers(emails: [String]) async -> Bool {
        let normalizedEmails = emails
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        guard normalizedEmails.isEmpty == false else { return false }

        do {
            try await groupService.inviteMembers(
                to: groupData.groupId,
                request: InviteGroupMembersRequest(emails: normalizedEmails)
            )
            try? await reloadGroupDataAndParticipants()
            return true
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
            return false
        }
    }

    func handleKickMember(email: String) async -> Bool {
        let normalizedEmail = email.normalizedEmailNonEmpty
        guard let normalizedEmail else { return false }

        do {
            try await groupService.kickMembers(
                from: groupData.groupId,
                request: KickGroupMembersRequest(emails: [normalizedEmail])
            )
            return true
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
            return false
        }
    }

    func handleCancelInvite(email: String) async -> Bool {
        let normalizedEmail = email.normalizedEmailNonEmpty
        guard let normalizedEmail else { return false }

        do {
            try await groupService.kickMembers(
                from: groupData.groupId,
                request: KickGroupMembersRequest(emails: [normalizedEmail])
            )
            return true
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
            return false
        }
    }

    func handleLeaveGroup() async {
        await presenter.closePreview()

        do {
            try await groupService.leaveGroup(by: groupData.groupId)
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
        }
    }

    func handleDeleteGroup() async {
        await presenter.closePreview()

        do {
            try await groupService.deleteGroup(by: groupData.groupId)
        } catch {
            await presenter.presentServiceError(GroupServiceError.wrap(error))
        }
    }

    // MARK: - Private Methods
    private func reloadGroupDataAndParticipants() async throws {
        async let groupTask = groupService.getGroup(by: groupData.groupId)
        async let currentUserIDTask = loadCurrentUserIDSilently()
        let (group, currentUserID) = try await (groupTask, currentUserIDTask)

        let resolvedTitle = group.normalizedName ?? groupData.title
        let resolvedSubtitle = group.normalizedDescription
        let resolvedAvatarUrl = group.normalizedAvatarUrl ?? groupData.avatarUrl
        let resolvedOwnerID = group.normalizedOwnerID ?? groupData.ownerId
        let isCurrentUserOwner = currentUserID != nil && currentUserID == resolvedOwnerID
            ? true
            : groupData.isCurrentUserOwner

        groupData = GroupPreviewModels.ViewData(
            groupId: groupData.groupId,
            title: resolvedTitle,
            subtitle: resolvedSubtitle,
            avatarUrl: resolvedAvatarUrl,
            ownerId: resolvedOwnerID,
            isCurrentUserOwner: isCurrentUserOwner
        )

        let participants = makeParticipantsViewData(
            group: group,
            currentUserID: currentUserID,
            ownerID: resolvedOwnerID,
            isCurrentUserOwner: isCurrentUserOwner
        )

        await presenter.presentGroup(groupData)
        await presenter.presentParticipants(participants)
    }

    private func loadCurrentUserIDSilently() async -> String? {
        do {
            let userDTO = try await userService.getUserProfile()
            let user = userDTO.toDomain()
            return user.id?.trimmedNonEmpty
        } catch {
            return nil
        }
    }

    private func makeParticipantsViewData(
        group: GroupWithMembers,
        currentUserID: String?,
        ownerID: String?,
        isCurrentUserOwner: Bool
    ) -> GroupPreviewModels.ParticipantsViewData {
        let members = group.members.map {
            makeParticipantViewData(
                member: $0,
                isInvited: false,
                currentUserID: currentUserID,
                ownerID: ownerID,
                isCurrentUserOwner: isCurrentUserOwner
            )
        }

        let invitedMembers = group.invitedUsers.map {
            makeParticipantViewData(
                member: $0,
                isInvited: true,
                currentUserID: currentUserID,
                ownerID: ownerID,
                isCurrentUserOwner: isCurrentUserOwner
            )
        }

        return GroupPreviewModels.ParticipantsViewData(
            members: members,
            invitedMembers: invitedMembers
        )
    }

    private func makeParticipantViewData(
        member: GroupMember,
        isInvited: Bool,
        currentUserID: String?,
        ownerID: String?,
        isCurrentUserOwner: Bool
    ) -> GroupPreviewModels.ParticipantViewData {
        let normalizedUserID = member.userId?.trimmedNonEmpty
        let normalizedEmail = member.email?.normalizedEmailNonEmpty
        let normalizedFirstName = member.firstName?.trimmedNonEmpty
        let normalizedLastName = member.lastName?.trimmedNonEmpty

        let fullName = [normalizedFirstName, normalizedLastName]
            .compactMap { $0 }
            .joined(separator: " ")

        let resolvedFullName: String = {
            if fullName.isEmpty == false {
                return fullName
            }
            return "participant".localized
        }()

        let isCurrentUser = normalizedUserID != nil && normalizedUserID == currentUserID
        let isOwner = normalizedUserID != nil && normalizedUserID == ownerID

        let rightAccessory: GroupPreviewModels.RightAccessory = {
            if isCurrentUser || (isCurrentUserOwner && isOwner) {
                return .you
            }

            if isCurrentUserOwner {
                if isInvited {
                    return normalizedEmail == nil ? .none : .removeInvite
                }
                return .kick
            }

            if isOwner {
                return .crown
            }

            return .none
        }()

        return GroupPreviewModels.ParticipantViewData(
            id: normalizedUserID.map { "user:\($0)" } ?? normalizedEmail.map { "email:\($0)" } ?? UUID().uuidString,
            email: normalizedEmail,
            fullName: resolvedFullName,
            avatarUrl: member.avatarUrl?.normalizedURLString,
            isInvited: isInvited,
            rightAccessory: rightAccessory
        )
    }
}

private extension Group {
    var normalizedName: String? {
        let value = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }

    var normalizedDescription: String? {
        let value = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }

    var normalizedAvatarUrl: String? {
        let value = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }
}

private extension GroupWithMembers {
    var normalizedName: String? {
        let value = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }

    var normalizedDescription: String? {
        let value = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }

    var normalizedAvatarUrl: String? {
        let value = avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }

    var normalizedOwnerID: String? {
        let value = ownerId?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, value.isEmpty == false else { return nil }
        return value
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return nil }
        return value
    }

    var normalizedEmailNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard value.isEmpty == false else { return nil }
        return value
    }

    var normalizedURLString: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
