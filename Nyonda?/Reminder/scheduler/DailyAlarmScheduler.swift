//
//  DailyAlarmScheduler.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/08.
//

import Foundation
import AlarmKit
import SwiftUI
import ActivityKit

struct DailyAlarmScheduler {
    
    func scheduleAlarm(at fireDate: Date) async throws -> Alarm {
        let id = UUID()
        
        let stopButton = AlarmButton(
            text: "停止",
            textColor: .white,
            systemImageName: "pawprint.circle"
        )
        
        let alert = AlarmPresentation.Alert(
            title:"くすりにょんだ？？",
            stopButton: stopButton
        )
        
        let presentation = AlarmPresentation(
            alert: alert
        )
        
        let attributes = AlarmAttributes<DailyAlarmMetadata>(
            presentation: presentation, tintColor: .blue
        )
        
        let reminderTime = DailyReminderTime(from:fireDate)
        
        let stopIntent = StopDailyAlarmIntent(
            alarmID: id.uuidString,
            hour: reminderTime.hour,
            minute: reminderTime.minute
        )
        
        let sound = AlertConfiguration.AlertSound.named("nyonda-alarm.caf")
        
        let configuration = AlarmManager.AlarmConfiguration<DailyAlarmMetadata>.alarm(schedule:.fixed(fireDate), attributes: attributes, stopIntent: stopIntent, secondaryIntent: nil, sound: sound)
        
        return try await AlarmManager.shared.schedule(id: id, configuration: configuration)
    
    }
}
