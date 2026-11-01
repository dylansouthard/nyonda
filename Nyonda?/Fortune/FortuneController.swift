//
//  FortuneController.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation
import Observation

@MainActor
@Observable
final class FortuneController {
    private(set) var todayFortune: DailyFortune?
    
    let store: DailyFortuneStore
    private let generator: FortuneGenerator
    private let paperCatalog: FortunePaperCatalog
    private let catalog: FortuneCatalog?
    
    var hasFortuneToday: Bool {
        guard let todayFortune else {return false}
        return AppDay.isToday(todayFortune.generatedAt, calendar: .autoupdatingCurrent)
    }
    
    @discardableResult
    func loadOrGenerateToday(for theme: CatTheme) -> DailyFortune {
        if let currentFortune = todayFortune, AppDay.isToday(currentFortune.generatedAt, calendar: .autoupdatingCurrent) {
            return currentFortune
        }
        
        restoreToday()
        
        if let restoredFortune = todayFortune {
            return restoredFortune
        }
        
        let newFortune = generator.generate(from: catalog, paperCatalog: paperCatalog, theme: theme)
        
        do {
            try store.save(newFortune)
        } catch {
            print("Could not save today's fortune: \(error)")
        }
        
        todayFortune = newFortune
        return newFortune
    }
    
    init()  {
        store = DailyFortuneStore()
        generator = FortuneGenerator()
        paperCatalog = FortunePaperCatalog()
        
        do {
            catalog = try FortuneCatalogLoader.load()
        } catch {
            catalog = nil
            print("Could not load fortune catalog; " + "fallback texts will be used: \(error)")
            
            restoreToday()
        }
    }
    
    func restoreToday() {
        do {
            todayFortune = try store.loadToday()
        } catch {
            print("Could not restore today's fortune: \(error)")
            store.clear()
            todayFortune = nil
        }
    }
}
