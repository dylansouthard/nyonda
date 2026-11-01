//
//  DailyFortuneStore.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation

@MainActor
final class DailyFortuneStore {
    private static let storageKey = "dailyFortune.v1"
    
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    func save(_ fortune: DailyFortune) throws {
        let data = try JSONEncoder().encode(fortune)
        defaults.set(data, forKey: Self.storageKey)
    }
    
    func load() throws -> DailyFortune? {
        guard let data = defaults.data(forKey: Self.storageKey) else {return nil}
        
        return try JSONDecoder().decode(DailyFortune.self, from: data)
    }
    
    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }
    
    func loadToday(relativeTo date: Date = .now, calendar: Calendar = .current) throws -> DailyFortune? {
        guard let fortune = try load() else {return nil}
        guard AppDay.isToday(fortune.generatedAt, relativeTo: date, calendar: calendar) else {
            clear()
            return nil
        }
        return fortune
    }
}
