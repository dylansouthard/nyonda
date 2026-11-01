//
//  StopDailyAlarmIntent.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/08.
//

import Foundation
import AlarmKit
import AppIntents

struct StopDailyAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource {
        "Stop Daily Alarm"
    }
    
    static var description: IntentDescription {
        IntentDescription("Stops the currently alerting daily alarm")
    }
    
    static var isDiscoverable: Bool {
        false
    }
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    @Parameter(title: "Hour")
    var hour: Int
    
    @Parameter(title: "Minute")
    var minute: Int

    
    init(alarmID: String, hour: Int, minute: Int) {
        self.alarmID = alarmID
        self.minute = minute
        self.hour = hour
    }
    
    init() {
        alarmID = ""
        hour = 0
        minute = 0
    }
    
    @MainActor
    func perform() async throws -> some IntentResult {
        guard let _ = UUID(uuidString: alarmID) else {
            return .result()
        }
        let reminderStore = ReminderStore()
        let alarmStore = AlarmStore()
        let alarmScheduler = DailyAlarmScheduler()
        let reminderSchedule = DailyReminderSchedule()
        
        guard reminderStore.isEnabled, reminderStore.reminderMode == .alarm else {
            print("Daily alarm is disabled; not scheduling another alarm.")
            return .result()
        }
        
        
        guard let alarmTime = DailyReminderTime(hour: hour, minute: minute), let nextFireDate = reminderSchedule.nextFireDate(for: alarmTime) else {
            print("Could not calculate the next alarm date.")
            return .result()
        }
        
        let nextAlarm = try await alarmScheduler.scheduleAlarm(at: nextFireDate)
        
        alarmStore.rememberAlarm(id: nextAlarm.id, fireDate: nextFireDate)
        
        print(
            "Scheduled next daily alarm \(nextAlarm.id) for \(nextFireDate)"
        )
        
        print("StopAlarmIntentExecuted for \(alarmID) for time \(hour):\(minute)")
        
        return .result()
    }
}
