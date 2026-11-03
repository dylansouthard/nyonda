//
//  NotificationService.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/25.
//

import SwiftUI

@MainActor
@Observable
final class NotificationService {
    private static let requestIdentifierPrefix = "nyonda.daily-reminder"
    private static let scheduleRequestCount = 30
    
    private let scheduler: NotificationScheduler
    private let reminderSchedule = DailyReminderSchedule()
    
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var notificationError: String?
    
    private(set) var scheduledDates:[Date] = []
    
    
    
    init () {
        self.scheduler = NotificationScheduler()
    }
    
    init(scheduler: NotificationScheduler) {
        self.scheduler = scheduler
    }
    
    private func refreshAuthorizationStatus() async {
        authorizationStatus = await scheduler.authorizationStatus()
    }
    
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await scheduler.requestAuthorization()
            await refreshAuthorizationStatus()
            notificationError = granted ? nil : "Notification permission was not  granted"
            return granted
        } catch {
            await refreshAuthorizationStatus()
            notificationError = error.localizedDescription
            return false
        }
    }
    
    
    private func ensureAuthorization() async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .notDetermined:
            return await requestAuthorization()
        case .denied:
            notificationError = "Notification permission has been denied."
            return false
        case .authorized, .provisional, .ephemeral:
            return true
            
        @unknown default:
            notificationError = "Unknown notification authorization status."
            return false
        }
    }
    
    private func pendingReminderRequests() async -> [UNNotificationRequest] {
        let requests = await scheduler.pendingRequests()
        return requests.filter { $0.identifier.hasPrefix(Self.requestIdentifierPrefix) }
    }
    
    private func makeNotificationContent() -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        
        content.title = String(localized: "おくすりにょんだ？？")
        content.body = String(localized: "お薬の時間です。")
        content.sound = .default

        return content
    }
    
    private func requestIdentifier(for fireDate: Date) -> String {
        let timestamp = Int(fireDate.timeIntervalSince1970)
        return "\(Self.requestIdentifierPrefix)\(timestamp)"
    }
    
    private func scheduleNotification(at fireDate: Date) async throws {
        let identifier = requestIdentifier(for: fireDate)
        let content = makeNotificationContent()
        try await scheduler.schedule(identifier: identifier, at: fireDate, content: content)
    }
    
    private func futureFireDates(for reminderTime: DailyReminderTime, after startDate: Date) -> [Date] {
        var fireDates:[Date] = []
        var searchDate = startDate
        
        for _ in 0..<Self.scheduleRequestCount {
            guard let fireDate = reminderSchedule.nextFireDate(for: reminderTime, after: searchDate) else { break }
            fireDates.append(fireDate)
            searchDate = fireDate
        }
        
        return fireDates
    }
    
    private func replacePendingSchedule(with desiredFireDates: [Date]) async -> Bool {
        let existingRequests = await pendingReminderRequests()
        let existingIdentifiers = existingRequests.map(\.identifier)
        let normalizedFireDates = Array(Set(desiredFireDates)).sorted()
        let desiredIdentifiers = Set(desiredFireDates.map{requestIdentifier(for: $0)})
        var newlyAddedIdentifiers: [String] = []
        do {
            for fireDate in normalizedFireDates {
                let identifier = requestIdentifier(for: fireDate)
                guard !existingIdentifiers.contains(identifier) else {continue}
                try await scheduleNotification(at: fireDate)
                if !existingIdentifiers.contains(identifier) {
                    newlyAddedIdentifiers.append(identifier)
                }
            }
        } catch {
            scheduler.removePendingRequests(withIdentifiers: newlyAddedIdentifiers)
            notificationError = error.localizedDescription
            return false
        }
        
        let obsoleteIdentifiers = existingRequests.map(\.identifier).filter{!desiredIdentifiers.contains($0)}
        if !obsoleteIdentifiers.isEmpty {
            scheduler.removePendingRequests(withIdentifiers: obsoleteIdentifiers)
        }
        
        scheduledDates = normalizedFireDates
        notificationError = nil
        
        return true
    }
    
    private func fireDate (for request: UNNotificationRequest) -> Date? {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {return nil}
        return trigger.nextTriggerDate()
    }
    
}

extension NotificationService: ReminderDeliveryService {
    var nextScheduledDate: Date? {
        return scheduledDates.first
    }
    
    var errorMessage: String? {
        notificationError
    }
    
    func enable(at time: DailyReminderTime) async -> Bool {
        guard await ensureAuthorization() else { return false }

        let existingRequests = await pendingReminderRequests()
        let existingDates = existingRequests
            .compactMap { fireDate(for: $0) }
            .sorted()

        if let firstDate = existingDates.first,
           firstDate > .now,
           DailyReminderTime(from: firstDate) == time {
            scheduledDates = existingDates
            notificationError = nil
            return true
        }

        let fireDates = futureFireDates(for: time, after: .now)
        guard !fireDates.isEmpty else {
            notificationError = "Could not calculate upcoming notification dates."
            return false
        }
        return await replacePendingSchedule(with: fireDates)
    }
    
    func disable() async -> Bool {
        let requests = await pendingReminderRequests()
        let identifiers = requests.map(\.identifier)
        if !identifiers.isEmpty {
            scheduler.removePendingRequests(withIdentifiers: identifiers)
        }
        
        scheduledDates = []
        
        return true
    }
    
    func updateTime(
        to time: DailyReminderTime,
        after startDate: Date
    ) async -> Bool {
        guard await ensureAuthorization() else { return false }
        
        let replacementDates = futureFireDates(
            for: time,
            after: startDate
        )
        
        guard !replacementDates.isEmpty else {
            notificationError = "Could not calculate the updated notification dates."
            return false
        }
        
        return await replacePendingSchedule(with: replacementDates)
        
    }
    
    func skipToday(at time: DailyReminderTime) async -> Bool {
        guard await ensureAuthorization() else {return false}
        
        let requests = await pendingReminderRequests()
        let pendingFireDates = requests.compactMap{fireDate(for:$0)}.sorted()
        guard let skippedFireDate = pendingFireDates.first, AppDay.isToday(skippedFireDate, calendar: .autoupdatingCurrent) else {
            notificationError = nil
            return true
        }
        
        let replacementDates = futureFireDates(for: time, after: skippedFireDate)
        
        guard !replacementDates.isEmpty else {
            notificationError = "Could not calculate notifications after today."
            return false
        }
        
        return await replacePendingSchedule(with: replacementDates)
        
    }
    
    func reconcile() async {
        await refreshAuthorizationStatus()
        let requests = await pendingReminderRequests()
        scheduledDates = requests.compactMap {fireDate(for: $0)}.sorted()
    }
    
    
}

