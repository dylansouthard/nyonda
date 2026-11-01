//
//  DailyReminderSchedule.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/18.
//

import Foundation

struct DailyReminderSchedule {
    private let calendar: Calendar
    
    init (calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }
    
    func nextFireDate(for selectedTime: Date, after date: Date = .now) -> Date? {
        let reminderTime = DailyReminderTime(from:selectedTime, calendar: calendar)
        
        return nextFireDate(for: reminderTime, after: date)
    }
    
    func nextFireDate(for reminderTime: DailyReminderTime, after date: Date = .now) -> Date? {
        calendar.nextDate(after: date, matching: reminderTime.dateComponents, matchingPolicy: .nextTime)
    }
    
}
