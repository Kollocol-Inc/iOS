//
//  GroupsLogicTests.swift
//  KollocolUnitTests
//
//  Created by Arsenii Potiakin on 28.04.2026.
//

import Testing
import Foundation
@testable import Kollocol

struct GroupsLogicTests {
    @Test @MainActor
    func groupsLogicCanBeInitializedAndUsedAsInteractor() {
        let presenter = GroupsPresenterMock()
        let groupService = GroupServiceMock()
        let userService = UserServiceMock()
        let interactor: GroupsInteractor = GroupsLogic(
            presenter: presenter,
            groupService: groupService,
            userService: userService
        )

        #expect((interactor as? GroupsLogic) != nil)
    }
}

private final class GroupsPresenterMock: GroupsPresenter {
    func presentGroups(
        memberGroups: [Group],
        ownerGroups: [Group],
        memberEmptyStateText: String?,
        ownerEmptyStateText: String?
    ) async {}

    func presentServiceError(_ error: GroupServiceError) async {}

    func presentGroupPreview(_ initialData: GroupPreviewModels.InitialData) async {}
}

private actor GroupServiceMock: GroupService {
    func getGroups() async throws -> [Group] { [] }
    func getGroups(filter: GroupFilter?) async throws -> [Group] { [] }
    func createGroup(_ request: CreateGroupRequest) async throws -> Group {
        Group(
            avatarUrl: nil,
            createdAt: nil,
            description: nil,
            id: nil,
            memberCount: nil,
            name: nil,
            ownerId: nil,
            pendingInvitesCount: nil,
            updatedAt: nil
        )
    }
    func getGroup(by groupId: String) async throws -> GroupWithMembers {
        GroupWithMembers(
            avatarUrl: nil,
            createdAt: nil,
            description: nil,
            id: nil,
            invitedUsers: [],
            memberCount: nil,
            members: [],
            name: nil,
            ownerId: nil,
            pendingInvitesCount: nil,
            updatedAt: nil
        )
    }
    func updateGroup(by groupId: String, _ request: UpdateGroupRequest) async throws -> Group {
        Group(
            avatarUrl: nil,
            createdAt: nil,
            description: nil,
            id: nil,
            memberCount: nil,
            name: nil,
            ownerId: nil,
            pendingInvitesCount: nil,
            updatedAt: nil
        )
    }
    func deleteGroup(by groupId: String) async throws {}
    func uploadGroupAvatar(data: Data) async throws -> String? { nil }
    func acceptGroupInvitation(by groupId: String) async throws -> Group {
        Group(
            avatarUrl: nil,
            createdAt: nil,
            description: nil,
            id: nil,
            memberCount: nil,
            name: nil,
            ownerId: nil,
            pendingInvitesCount: nil,
            updatedAt: nil
        )
    }
    func declineGroupInvitation(by groupId: String) async throws {}
    func inviteMembers(to groupId: String, request: InviteGroupMembersRequest) async throws {}
    func kickMembers(from groupId: String, request: KickGroupMembersRequest) async throws {}
    func leaveGroup(by groupId: String) async throws {}
}

private actor UserServiceMock: UserService {
    func getUserProfile() async throws -> UserDTO {
        UserDTO(
            avatarUrl: nil,
            createdAt: nil,
            email: "owner@kollocol.com",
            firstName: "Owner",
            id: "owner-id",
            lastName: "User",
            updatedAt: nil
        )
    }

    func updateUserProfile(name: String, surname: String) async throws -> UserDTO {
        UserDTO(
            avatarUrl: nil,
            createdAt: nil,
            email: "owner@kollocol.com",
            firstName: name,
            id: "owner-id",
            lastName: surname,
            updatedAt: nil
        )
    }

    func uploadAvatar(data: Data) async throws {}
    func getNotifications() async throws -> NotificationsSettingsDTO {
        NotificationsSettingsDTO(
            deadlineReminder: "one_hour",
            groupInvites: true,
            newQuizzes: true,
            quizResults: true,
            userId: nil
        )
    }

    func updateNotifications(
        deadlineReminder: String,
        groupInvites: Bool,
        newQuizzes: Bool,
        quizResults: Bool
    ) async throws -> NotificationsSettingsDTO {
        NotificationsSettingsDTO(
            deadlineReminder: deadlineReminder,
            groupInvites: groupInvites,
            newQuizzes: newQuizzes,
            quizResults: quizResults,
            userId: nil
        )
    }

    func register(name: String, surname: String) async throws {}
    func deleteAvatar() async throws {}
    func deleteUserAccount() async throws {}
}
