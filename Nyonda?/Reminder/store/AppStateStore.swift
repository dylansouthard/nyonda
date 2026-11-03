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
    
    private enum Key {
        static let lastTakenDate = "appstate.lastTakenDate"
    }
    
    private(set) var lastTakenDate: Date?
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastTakenDate = defaults.object(forKey: Key.lastTakenDate) as? Date
    }
    
    var hasTakenMedicineToday: Bool {
        guard let lastTakenDate else {return false}
        return AppDay.isToday(lastTakenDate, calendar: .autoupdatingCurrent)
    }
    
    var canMarkMedicineTaken: Bool {
        !hasTakenMedicineToday
    }
    
    @discardableResult
    func markMedicineTaken(at date: Date = .now) -> Bool {
        if let lastTakenDate, AppDay.isSameDay(lastTakenDate, date, calendar: .autoupdatingCurrent) {
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
