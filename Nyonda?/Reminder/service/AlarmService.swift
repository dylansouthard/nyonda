//
//  AlarmService.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/18.
//

import Foundation
import AlarmKit
import Observation

@MainActor
@Observable
final class AlarmService: ReminderDeliveryService {

    
    private let manager = AlarmManager.shared
    private let reminderSchedule: DailyReminderSchedule
    private let scheduler: DailyAlarmScheduler
    private let store: AlarmStore
    
    private(set) var authorizationState = AlarmManager.shared.authorizationState
    private(set) var authorizationError: String?
    private(set) var alarmError: String?
    
    private(set) var scheduledAlarmID: UUID?
    private(set) var scheduledFireDate: Date?
    var nextScheduledDate: Date? {
        scheduledFireDate
    }
    var errorMessage: String? {
        alarmError ?? authorizationError
    }
    init() {
        let store = AlarmStore()
        self.reminderSchedule = DailyReminderSchedule()
        self.scheduler = DailyAlarmScheduler()
        self.store = store
        self.scheduledAlarmID = store.scheduledAlarmID
        self.scheduledFireDate = store.scheduledFireDate
        
    }
    
    func enable(at time: DailyReminderTime) async -> Bool {
        alarmError = nil
        
        guard await ensureAuthorization() else {return false}
        guard let nextFireDate = reminderSchedule.nextFireDate(for: time) else {
            alarmError = "Could not calculate the next reminder time"
            return false
        }
        
        if let scheduledFireDate {
            let scheduledTime = DailyReminderTime(from: scheduledFireDate)
            if scheduledFireDate > .now, scheduledTime == time {return true}
            return await replaceScheduledAlarm(with: nextFireDate)
        }
        
        return await scheduleAlarm(at: nextFireDate)
        
    }
    
    func disable() async -> Bool {
        cancelScheduledAlarm()
    }
    
    func updateTime(
        to time: DailyReminderTime,
        after startDate: Date
    ) async -> Bool {
        guard await ensureAuthorization() else { return false }
        guard let nextFireDate = reminderSchedule.nextFireDate(
            for: time,
            after: startDate
        ) else {
            alarmError = "Could not calculate the updated reminder time."
            return false
        }
        
        if scheduledAlarmID == nil {
            return await scheduleAlarm(at: nextFireDate)
        }
        
        return await replaceScheduledAlarm(with: nextFireDate)
    }
    
    func ensureAuthorization() async -> Bool {
        authorizationState = manager.authorizationState
        
        if authorizationState == .authorized {
            authorizationError = nil
            return true
        }
        
        do {
            authorizationState = try await manager.requestAuthorization()
            authorizationError = nil
            return authorizationState == .authorized
        } catch {
            authorizationError = error.localizedDescription
            return false
        }
    }
    
    func skipToday(at time: DailyReminderTime) async -> Bool {
        alarmError = nil
        guard let currentFireDate = scheduledFireDate else {
            alarmError = "There was no scheduled alarm to skip."
            return false
        }
        
        guard let nextFireDate = reminderSchedule.nextFireDate(for: time, after:currentFireDate) else {
            alarmError = "Could not calculate the next reminder time"
            return false
        }
        
        return await replaceScheduledAlarm(with: nextFireDate)
    }

    func reconcile() async {
        do {
            let currentAlarms = try manager.alarms
            reconcileAlarmState(with: currentAlarms)
        } catch {
            alarmError = error.localizedDescription
        }
    }
    
    func monitorUpdates() async {
        await reconcile()
        for await alarms in manager.alarmUpdates {
            reconcileAlarmState(with: alarms)
        }
    }
    
    private func scheduleAlarm(at fireDate: Date) async -> Bool {
        guard authorizationState == .authorized else {
            alarmError = "Alarm permissions have not been granted"
            return false
        }
        
        do {
            let alarm = try await scheduler.scheduleAlarm(at: fireDate)
            rememberAlarm(id: alarm.id, fireDate: fireDate)
            alarmError = nil
            return true
        } catch {
            alarmError = error.localizedDescription
            return false
        }
    }
    
    private func cancelScheduledAlarm() -> Bool {
        guard let id = scheduledAlarmID else {
            alarmError = nil
            return true
        }
        
        do {
            try manager.cancel(id: id)
            forgetAlarm()
            alarmError = nil
            return true
        } catch {
            alarmError = error.localizedDescription
            return false
        }
    }
    
    private func replaceScheduledAlarm(with nextFireDate:Date) async -> Bool {
        guard let currentID = scheduledAlarmID, let currentFireDate = scheduledFireDate else {
            alarmError = "There is no scheduled alarm to replace"
            return false
        }
        do {
            let replacementAlarm = try await scheduler.scheduleAlarm(at: nextFireDate)
            rememberAlarm(id: replacementAlarm.id, fireDate: nextFireDate)
            
            do {
                try manager.cancel(id: currentID)
            } catch {
                try? manager.cancel(id: replacementAlarm.id)
                rememberAlarm(id: currentID, fireDate: currentFireDate)
                throw error
            }
            alarmError = nil
            return true
        } catch {
            alarmError = error.localizedDescription
            return false
        }
    }
    
    private func rememberAlarm(id: UUID, fireDate:Date) {
        scheduledAlarmID = id
        scheduledFireDate = fireDate
        store.rememberAlarm(id: id, fireDate: fireDate)
    }
    
    private func forgetAlarm() {
        scheduledAlarmID = nil
        scheduledFireDate = nil
        store.forgetAlarm()
    }
    
    private func reconcileAlarmState(with alarms: [Alarm]) {
        let storedAlarmID = store.scheduledAlarmID
        let storedFireDate = store.scheduledFireDate
        
        if storedAlarmID != scheduledAlarmID || storedFireDate != scheduledFireDate {
            scheduledAlarmID = storedAlarmID
            scheduledFireDate = storedFireDate
        }
        
        guard let currentID = scheduledAlarmID else {
            return
        }
        
        let alarmStillExists = alarms.contains {
            $0.id == currentID
        }
        
        if !alarmStillExists {
            forgetAlarm()
        }
    }
}
