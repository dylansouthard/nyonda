//
//  DailyAlarmTime.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import Foundation


struct DailyReminderTime: Equatable, Codable {
    let hour: Int
    let minute: Int
    
    init(from date: Date, calendar: Calendar = .autoupdatingCurrent) {
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
    }
    
    init?(hour: Int, minute:Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else { return nil }
        self.hour = hour
        self.minute = minute
    }
    
    var dateComponents: DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        components.second = 0
        return components
    }
}
