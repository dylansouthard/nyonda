//
//  DailyAlarmStore.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import Foundation

final class AlarmStore {
    private let defaults: UserDefaults
    private enum Key {
        static let scheduledAlarmID = "scheduledAlarmID"
        static let scheduledFireDate = "scheduledFireDate"
    }
    
    var scheduledAlarmID: UUID? {
        guard let storedValue = defaults.string(forKey: Key.scheduledAlarmID) else {return nil}
        return UUID(uuidString: storedValue)
    }
    
    var scheduledFireDate: Date? {
        defaults.object(forKey: Key.scheduledFireDate) as? Date
    }
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func rememberAlarm(id:UUID, fireDate: Date) {
        defaults.set(id.uuidString, forKey: Key.scheduledAlarmID)
        defaults.set(fireDate, forKey: Key.scheduledFireDate)
    }
    
    func forgetAlarm() {
        defaults.removeObject(
            forKey: Key.scheduledAlarmID
        )

        defaults.removeObject(
            forKey: Key.scheduledFireDate
        )
    }
}
