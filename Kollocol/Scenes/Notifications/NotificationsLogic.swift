//
//  NotificationsLogic.swift
//  Kollocol
//
//  Created by Arsenii Potiakin on 08.05.2026.
//

import Foundation

@MainActor
final class NotificationsLogic: NotificationsInteractor {
    // MARK: - Constants
    private enum Pagination {
        static let limit = 100
        static let offset = 0
    }

    private enum ReadBatching {
        static let debounceNanoseconds: UInt64 = 250_000_000
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "dd.MM"
        return formatter
    }()

    // MARK: - Properties
    private let presenter: NotificationsPresenter
    private let notificationsService: NotificationsService
    private let groupService: GroupService

    private var notifications: [NotificationsModels.NotificationViewData] = []
    private var pendingVisibleReadNotificationIDs = Set<String>()
    private var sentReadNotificationIDs = Set<String>()
    private var pendingReadFlushTask: Task<Void, Never>?

    // MARK: - Lifecycle
    init(
        presenter: NotificationsPresenter,
        notificationsService: NotificationsService,
        groupService: GroupService
    ) {
        self.presenter = presenter
        self.notificationsService = notificationsService
        self.groupService = groupService
    }

    // MARK: - Methods
    func handleViewDidLoad() async {
        do {
            let response = try await notificationsService.getNotifications(
                GetUserNotificationsRequest(
                    limit: Pagination.limit,
                    offset: Pagination.offset
                )
            )

            let mappedNotifications = response.notifications.map { mapNotification($0) }
            notifications = sortNotifications(mappedNotifications)
            await presenter.presentNotifications(notifications)
        } catch {
            await presenter.presentNotifications([])
            await presenter.presentServiceError(NotificationsServiceError.wrap(error))
        }
    }

    func handleNotificationWillDisplay(notificationId: String) async {
        guard let notification = notifications.first(where: { $0.id == notificationId }) else { return }
        guard notification.isRead == false else { return }
        guard notification.type != .groupInvite else { return }
        guard sentReadNotificationIDs.contains(notification.id) == false else { return }
        guard pendingVisibleReadNotificationIDs.contains(notification.id) == false else { return }

        pendingVisibleReadNotificationIDs.insert(notification.id)
        schedulePendingReadFlushIfNeeded()
    }

    func handleInviteAction(
        notificationId: String,
        action: NotificationsModels.InviteAction
    ) async {
        guard let notification = notifications.first(where: { $0.id == notificationId }) else { return }
        guard notification.type == .groupInvite else { return }
        guard notification.isInviteActionInProgress == false else { return }

        updateNotification(notificationId: notificationId) { notification in
            NotificationsModels.NotificationViewData(
                id: notification.id,
                groupId: notification.groupId,
                title: notification.title,
                description: notification.description,
                type: notification.type,
                isRead: notification.isRead,
                createdAt: notification.createdAt,
                dateText: notification.dateText,
                isInviteActionInProgress: true
            )
        }
        await presenter.presentNotifications(notifications)

        guard let groupId = resolveInviteTargetGroupId(for: notification) else {
            updateNotification(notificationId: notificationId) { notification in
                NotificationsModels.NotificationViewData(
                    id: notification.id,
                    groupId: notification.groupId,
                    title: notification.title,
                    description: notification.description,
                    type: notification.type,
                    isRead: notification.isRead,
                    createdAt: notification.createdAt,
                    dateText: notification.dateText,
                    isInviteActionInProgress: false
                )
            }
            await presenter.presentNotifications(notifications)
            await presenter.presentServiceError(GroupServiceError.badRequest)
            return
        }

        do {
            switch action {
            case .accept:
                _ = try await groupService.acceptGroupInvitation(by: groupId)

            case .ignore:
                try await groupService.declineGroupInvitation(by: groupId)
            }

            do {
                try await notificationsService.markNotificationsAsRead(
                    NotificationIDsRequest(ids: [notification.id])
                )
                sentReadNotificationIDs.insert(notification.id)
                pendingVisibleReadNotificationIDs.remove(notification.id)
            } catch {
                // UI state is updated locally regardless; backend will synchronize on next reload.
            }

            updateNotification(notificationId: notificationId) { notification in
                NotificationsModels.NotificationViewData(
                    id: notification.id,
                    groupId: notification.groupId,
                    title: notification.title,
                    description: notification.description,
                    type: notification.type,
                    isRead: true,
                    createdAt: notification.createdAt,
                    dateText: notification.dateText,
                    isInviteActionInProgress: false
                )
            }
            await presenter.presentNotifications(notifications)
        } catch {
            updateNotification(notificationId: notificationId) { notification in
                NotificationsModels.NotificationViewData(
                    id: notification.id,
                    groupId: notification.groupId,
                    title: notification.title,
                    description: notification.description,
                    type: notification.type,
                    isRead: notification.isRead,
                    createdAt: notification.createdAt,
                    dateText: notification.dateText,
                    isInviteActionInProgress: false
                )
            }
            await presenter.presentNotifications(notifications)
            await presenter.presentServiceError(GroupServiceError.wrap(error))
        }
    }

    // MARK: - Private Methods
    private func mapNotification(_ notification: UserNotification) -> NotificationsModels.NotificationViewData {
        let notificationId = notification.id?.trimmedNonEmpty ?? UUID().uuidString
        let title = notification.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let description = notification.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let dateText: String?
        if let createdAt = notification.createdAt {
            dateText = Self.shortDateFormatter.string(from: createdAt)
        } else {
            dateText = nil
        }

        return NotificationsModels.NotificationViewData(
            id: notificationId,
            groupId: notification.groupId?.trimmedNonEmpty,
            title: title,
            description: description,
            type: mapNotificationType(notification.type),
            isRead: notification.isRead ?? false,
            createdAt: notification.createdAt,
            dateText: dateText,
            isInviteActionInProgress: false
        )
    }

    private func mapNotificationType(_ type: UserNotificationType) -> NotificationsModels.NotificationType {
        switch type {
        case .groupInvite:
            return .groupInvite
        case .quizCreated:
            return .quizCreated
        case .quizResults:
            return .quizResults
        case .gradeChanged:
            return .gradeChanged
        case .deadlineReminder:
            return .deadlineReminder
        case .groupKicked:
            return .groupKicked
        case .unknown:
            return .unknown
        }
    }

    private func sortNotifications(_ value: [NotificationsModels.NotificationViewData]) -> [NotificationsModels.NotificationViewData] {
        let unread = value
            .filter { $0.isRead == false }
            .sorted(by: compareNotificationsByDate)

        let read = value
            .filter { $0.isRead }
            .sorted(by: compareNotificationsByDate)

        return unread + read
    }

    private func compareNotificationsByDate(
        lhs: NotificationsModels.NotificationViewData,
        rhs: NotificationsModels.NotificationViewData
    ) -> Bool {
        switch (lhs.createdAt, rhs.createdAt) {
        case let (.some(lhsDate), .some(rhsDate)):
            if lhsDate == rhsDate {
                return lhs.id > rhs.id
            }
            return lhsDate > rhsDate
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            return lhs.id > rhs.id
        }
    }

    private func resolveInviteTargetGroupId(
        for notification: NotificationsModels.NotificationViewData
    ) -> String? {
        // Backend payloads may carry invitation target under `group_id`
        // or reuse notification `id` as the target identifier.
        notification.groupId?.trimmedNonEmpty
            ?? notification.id.trimmedNonEmpty
    }

    private func updateNotification(
        notificationId: String,
        transform: (NotificationsModels.NotificationViewData) -> NotificationsModels.NotificationViewData
    ) {
        guard let index = notifications.firstIndex(where: { $0.id == notificationId }) else { return }
        notifications[index] = transform(notifications[index])
    }

    private func schedulePendingReadFlushIfNeeded() {
        guard pendingReadFlushTask == nil else { return }

        pendingReadFlushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: ReadBatching.debounceNanoseconds)
            await self?.flushPendingReadNotifications()
            await self?.clearPendingReadFlushTask()
        }
    }

    private func clearPendingReadFlushTask() {
        pendingReadFlushTask = nil

        if pendingVisibleReadNotificationIDs.isEmpty == false {
            schedulePendingReadFlushIfNeeded()
        }
    }

    private func flushPendingReadNotifications() async {
        let ids = Array(pendingVisibleReadNotificationIDs)
        guard ids.isEmpty == false else { return }

        pendingVisibleReadNotificationIDs.removeAll()
        sentReadNotificationIDs.formUnion(ids)

        do {
            try await notificationsService.markNotificationsAsRead(
                NotificationIDsRequest(ids: ids)
            )
        } catch {
            sentReadNotificationIDs.subtract(ids)
        }
    }
}

// MARK: - String
private extension String {
    var trimmedNonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        guard value.isEmpty == false else { return nil }
        return value
    }
}
