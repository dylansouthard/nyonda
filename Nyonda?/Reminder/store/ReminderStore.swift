//
//  ReminderStore.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/18.
//

//
//  DailyAlarmStore.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import Foundation

final class ReminderStore {
    private let defaults: UserDefaults
    private enum Key {
        static let selectedTime = "selectedTime"
        static let isEnabled = "isEnabled"
        static let reminderMode = "reminderMode"
    }
    
    var selectedTime: Date? {
        defaults.object(forKey: Key.selectedTime) as? Date
    }
    
    var isEnabled: Bool {
        defaults.bool(forKey: Key.isEnabled)
    }
    
    var reminderMode:ReminderMode {
        guard let rawValue = defaults.string(forKey: Key.reminderMode), let mode = ReminderMode(rawValue: rawValue) else {return .alarm}
        return mode
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    
    func saveSelectedTime(_ selectedTime: Date) {
        defaults.set(
            selectedTime,
            forKey: Key.selectedTime
        )
    }

    func saveIsEnabled(_ isEnabled: Bool) {
        defaults.set(
            isEnabled,
            forKey: Key.isEnabled
        )
    }
    
    func saveReminderMode(_ reminderMode: ReminderMode) {
        defaults.set(reminderMode.rawValue, forKey: Key.reminderMode)
    }
    
    
}
