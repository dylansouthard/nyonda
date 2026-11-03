//
//  AppStateStore.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/11/01.
//

import Foundation
import Observation

@MainActor
@Observable
final class AppStateStore {
    private let defaults:UserDefaults
    private let calendar: Calendar
    private let now: () -> Date
    
    private enum Key {
        static let lastTakenDate = "appstate.lastTakenDate"
        static let legacyLastTakenDate = "lastTakenDate"
    }
    
    private(set) var lastTakenDate: Date?
    
    init(
        defaults: UserDefaults = .standard,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = { .now }
    ) {
        self.defaults = defaults
        self.calendar = calendar
        self.now = now

        if let currentDate = defaults.object(forKey: Key.lastTakenDate) as? Date {
            self.lastTakenDate = currentDate
        } else if let legacyDate = defaults.object(forKey: Key.legacyLastTakenDate) as? Date {
            defaults.set(legacyDate, forKey: Key.lastTakenDate)
            defaults.removeObject(forKey: Key.legacyLastTakenDate)
            self.lastTakenDate = legacyDate
        } else {
            self.lastTakenDate = nil
        }
    }
    
    var hasTakenMedicineToday: Bool {
        guard let lastTakenDate else {return false}
        return AppDay.isToday(lastTakenDate, relativeTo: now(), calendar: calendar)
    }
    
    var canMarkMedicineTaken: Bool {
        !hasTakenMedicineToday
    }
    
    @discardableResult
    func markMedicineTaken(at date: Date = .now) -> Bool {
        if let lastTakenDate, AppDay.isSameDay(lastTakenDate, date, calendar: calendar) {
            return false
        }
        lastTakenDate = date
        defaults.set(date, forKey: Key.lastTakenDate)
        return true
    }
    
    @discardableResult
    func undoMedicineTakenToday() -> Bool {
        guard hasTakenMedicineToday else {
            return false
        }
        
        lastTakenDate = nil
        defaults.removeObject(forKey: Key.lastTakenDate)
        return true
    }
}
