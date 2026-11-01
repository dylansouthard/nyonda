//
//  FortuneGenerator.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation
struct FortuneGenerator {
   private static let fallbackTexts = [
        "猫が占い札を踏んだため、この運勢は読み取れず。",
        "神託の途中で猫が眠った。続きは猫のみぞ知る。",
        "猫がみくじを持ち去ったため、結果はただいま不明なり。",
        "猫の尾が肝心な文字を隠している。今日は深追いするな。",
        "占いの紙は猫の座布団となった。結果はまた後日。",
        "猫は答えを知っている顔だが、語るつもりはない。",
        "神託を受けた猫、ただいま毛づくろい中。しばし待て。",
        "猫が占い箱を倒したため、吉凶入り乱れて判別不能なり。",
        "啓示は届いたが猫が噛んだ。肝心なところだけ読めぬ。",
        "猫神さま本日は休業なり。この運勢は己で決めよ。"
      ]
    private static let emergencyFallback = "猫神さま本日は休業なり。この運勢は己で決めよ。"
    
    
    func generate(from catalog: FortuneCatalog?, paperCatalog:FortunePaperCatalog, theme:CatTheme, at date:Date = .now) -> DailyFortune {
        let level = randomLevel()
        var selectedTexts: [FortuneCategory: String] = [:]
        
        for category in  FortuneCategory.allCases {
            selectedTexts[category] = randomText(for:category, level: level, from:catalog)
        }
        let paperName = randomPaperName(for: level, theme: theme, from: paperCatalog)
        return DailyFortune(generatedAt: date, level: level, paperImageName: paperName, texts: selectedTexts)
    }
    
    private func randomPaperName(for level: FortuneLevel, theme:CatTheme, from paperCatalog: FortunePaperCatalog) -> String {
        paperCatalog.options(for: theme, tone: level.tone).randomElement() ?? paperCatalog.fallbackImageName(for: theme)
    }
    
    
    private func randomLevel() -> FortuneLevel {
        let roll = Int.random(in: 0..<100)
        return FortuneLevel.allCases.first {
            $0.rollRange.contains(roll)
        } ?? .kichi
    }
    
    private func randomText(for category: FortuneCategory, level: FortuneLevel, from catalog: FortuneCatalog?) -> String {
        catalog?.options(for: category, level: level).randomElement() ?? Self.fallbackTexts.randomElement() ?? Self.emergencyFallback
    }
    
    
}
