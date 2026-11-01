//
//  NotificationScheduler.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/25.
//

import Foundation
import UserNotifications

struct NotificationScheduler {
    private let notificationCenter: UNUserNotificationCenter
    private let calendar: Calendar
    
    init(notificationCenter: UNUserNotificationCenter = .current(), calendar: Calendar = .autoupdatingCurrent) {
        self.notificationCenter = notificationCenter
        self.calendar = calendar
    }
    
    func authorizationStatus () async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }
    
    func requestAuthorization() async throws -> Bool {
        try await notificationCenter.requestAuthorization(options: [.alert, .sound])
    }
    
    func schedule(identifier: String, at fireDate:Date, content: UNNotificationContent) async throws {
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        components.calendar = calendar
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await notificationCenter.add(request)
    }
    
    func pendingRequests() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    func removePendingRequests(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    
}
