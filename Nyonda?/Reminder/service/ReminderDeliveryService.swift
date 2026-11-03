//
//  ReminderDeliveryService.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/19.
//

import SwiftUI

@MainActor
protocol ReminderDeliveryService: AnyObject {
    var nextScheduledDate: Date? {get}
    var errorMessage: String? {get}
    
    @discardableResult
    func enable(at time: DailyReminderTime) async -> Bool
    
    @discardableResult
    func disable() async -> Bool
    
    @discardableResult
    func updateTime(
        to time: DailyReminderTime,
        after startDate: Date
    ) async -> Bool
    
    @discardableResult
    func skipToday(at time: DailyReminderTime) async -> Bool
    func reconcile() async
}

extension ReminderDeliveryService {
    @discardableResult
    func updateTime(to time: DailyReminderTime) async -> Bool {
        await updateTime(to: time, after: .now)
    }

    func monitorUpdates() async {
        await reconcile()
    }
}
