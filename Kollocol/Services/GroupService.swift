//
//  GroupService.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 02.05.2026.
//

import Foundation

// MARK: - GroupServiceImpl
actor GroupServiceImpl: GroupService {
    // MARK: - Properties
    private let api: APIClient

    // MARK: - Lifecycle
    init(api: APIClient) {
        self.api = api
    }

    // MARK: - Methods
    func getGroups() async throws -> [Group] {
        return try await getGroups(filter: .my)
    }

    func getGroups(filter: GroupFilter?) async throws -> [Group] {
        do {
            let response = try await api.request(GetGroupsEndpoint(filter: filter))
            return response.groups.map { $0.toDomain() }
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func createGroup(_ request: CreateGroupRequest) async throws -> Group {
        do {
            let dto = request.toDto()
            let response = try await api.request(CreateGroupEndpoint(request: dto))
            return response.toDomain()
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func getGroup(by groupId: String) async throws -> GroupWithMembers {
        do {
            let response = try await api.request(GetGroupByIdEndpoint(groupId: groupId))
            return response.toDomain()
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func updateGroup(by groupId: String, _ request: UpdateGroupRequest) async throws -> Group {
        do {
            let dto = request.toDto()
            let response = try await api.request(UpdateGroupEndpoint(groupId: groupId, request: dto))
            return response.toDomain()
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func deleteGroup(by groupId: String) async throws {
        do {
            _ = try await api.request(DeleteGroupEndpoint(groupId: groupId))
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func uploadGroupAvatar(data: Data) async throws -> String? {
        do {
            let file = UploadGroupAvatarEndpoint.AvatarFile(data: data)
            let response = try await api.request(UploadGroupAvatarEndpoint(avatar: file))
            let avatarUrl = response.avatarUrl?.trimmingCharacters(in: .whitespacesAndNewlines)
            return avatarUrl?.isEmpty == false ? avatarUrl : nil
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func acceptGroupInvitation(by groupId: String) async throws -> Group {
        do {
            let response = try await api.request(AcceptGroupInvitationEndpoint(groupId: groupId))
            return response.toDomain()
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func declineGroupInvitation(by groupId: String) async throws {
        do {
            _ = try await api.request(DeclineGroupInvitationEndpoint(groupId: groupId))
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func inviteMembers(to groupId: String, request: InviteGroupMembersRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(InviteGroupMembersEndpoint(groupId: groupId, request: dto))
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func kickMembers(from groupId: String, request: KickGroupMembersRequest) async throws {
        do {
            let dto = request.toDto()
            _ = try await api.request(KickGroupMembersEndpoint(groupId: groupId, request: dto))
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }

    func leaveGroup(by groupId: String) async throws {
        do {
            _ = try await api.request(LeaveGroupEndpoint(groupId: groupId))
        } catch {
            throw GroupServiceError.wrap(error)
        }
    }
}

// MARK: - GroupService
protocol GroupService: Actor {
    func getGroups() async throws -> [Group]
    func getGroups(filter: GroupFilter?) async throws -> [Group]
    func createGroup(_ request: CreateGroupRequest) async throws -> Group
    func getGroup(by groupId: String) async throws -> GroupWithMembers
    func updateGroup(by groupId: String, _ request: UpdateGroupRequest) async throws -> Group
    func deleteGroup(by groupId: String) async throws
    func uploadGroupAvatar(data: Data) async throws -> String?
    func acceptGroupInvitation(by groupId: String) async throws -> Group
    func declineGroupInvitation(by groupId: String) async throws
    func inviteMembers(to groupId: String, request: InviteGroupMembersRequest) async throws
    func kickMembers(from groupId: String, request: KickGroupMembersRequest) async throws
    func leaveGroup(by groupId: String) async throws
}

// MARK: - GroupServiceError
enum GroupServiceError: Error, Sendable {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case server
    case offline
    case unknown

    static func mapStatusCode(_ code: Int) -> GroupServiceError? {
        if code == 400 { return .badRequest }
        if code == 401 { return .unauthorized }
        if code == 403 { return .forbidden }
        if code == 404 { return .notFound }
        if code == 409 { return .conflict }
        if (500...599).contains(code) { return .server }

        return nil
    }
}

extension GroupServiceError: NetworkServiceError {}
