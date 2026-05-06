//
//  GroupPreviewProtocols.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 06.05.2026.
//

import Foundation

@MainActor
protocol GroupPreviewInteractor {
    func handleViewDidLoad() async
    func handleEditGroup(_ request: GroupPreviewModels.EditGroupRequest) async -> Bool
    func handleInviteMembers(emails: [String]) async -> Bool
    func handleKickMember(email: String) async -> Bool
    func handleCancelInvite(email: String) async -> Bool
    func handleLeaveGroup() async
    func handleDeleteGroup() async
}

@MainActor
protocol GroupPreviewPresenter {
    func presentGroup(_ data: GroupPreviewModels.ViewData) async
    func presentParticipants(_ data: GroupPreviewModels.ParticipantsViewData) async
    func closePreview() async
    func presentServiceError(_ error: GroupServiceError) async
}
