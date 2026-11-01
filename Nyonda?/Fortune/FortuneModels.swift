//
//  FortuneModels.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation
import UIKit

enum FortuneLevel: String, Codable, CaseIterable {
    case daikichi
    case chukichi
    case kichi
    case shokichi
    case suekichi
    case kyo
    case daikyo

    var displayName: String {
        switch self {
        case .daikichi:
            return "大吉"
        case .chukichi:
            return "中吉"
        case .kichi:
            return "吉"
        case .shokichi:
            return "小吉"
        case .suekichi:
            return "末吉"
        case .kyo:
            return "凶"
        case .daikyo:
            return "大凶"
        }
    }
    
    var tone: FortuneTone {
        switch self {
        case .daikichi, .chukichi:
            return .positive

        case .shokichi, .suekichi, .kichi:
            return .neutral

        case .kyo, .daikyo:
            return .negative
        }
    }
    
    var rollRange: Range<Int> {
        switch self {
        case .daikyo:
            return 0..<5       // 5%
        case .kyo:
            return 5..<15      // 10%
        case .suekichi:
            return 15..<30     // 15%
        case .shokichi:
            return 30..<50     // 20%
        case .kichi:
            return 50..<70     // 20%
        case .chukichi:
            return 70..<90     // 20%
        case .daikichi:
            return 90..<100    // 10%
        }
    }
}

enum FortuneCategory: String, Codable, CaseIterable, Identifiable {
    case summary
    case desires
    case career
    case love
    case relationships
    case wealth
    case travel
    case health
    case lostItems = "lost_items"
    case catWisdom = "cat_wisdom"

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .summary:
            return "総合運"
        case .wealth:
            return "金運"
        case .health:
            return "健康運"
        case .travel:
            return "おでかけ"
        case .love:
            return "恋愛"
        case .desires:
            return "願い事"
        case .relationships:
            return "人間関係"
        case .catWisdom:
            return "猫のお告げ"
        case .career:
            return "仕事"
        case .lostItems:
            return "失せ物"
        }
    }
}

enum FortuneTone: Hashable {
    case positive
    case neutral
    case negative
}

struct DailyFortune:Codable {
    let generatedAt: Date
    let level: FortuneLevel
    let paperImageName: String
    let texts: [FortuneCategory: String]
    
    static let dummy = DailyFortune(generatedAt: .now, level: .kichi, paperImageName: "ame_14", texts: [Nyonda_.FortuneCategory.lostItems: "急いで探せば見落とす。ひと息ついてから再び見よ。", Nyonda_.FortuneCategory.love: "夫の相談には優しく応じると吉", Nyonda_.FortuneCategory.wealth: "作品集を少し整えれば、見つけてくれる人が増える。", Nyonda_.FortuneCategory.travel: "予定を詰めずに出れば、気の向くまま楽しめる。", Nyonda_.FortuneCategory.catWisdom: "人間が厠へ向かう時、必ず付き従え。ひとりにしてはならぬ。", Nyonda_.FortuneCategory.summary: "よき知らせはささやかな形で来る。心静かに待て。", Nyonda_.FortuneCategory.relationships: "言葉少なくとも心は通じる。静かな時間を大切にせよ。", Nyonda_.FortuneCategory.desires: "小さき努力を重ねれば、求める結果に近づく。", Nyonda_.FortuneCategory.career: "小さな誤りに早く気づく。直せば支障なし。", Nyonda_.FortuneCategory.health: "体調の変化を書き留めれば、自分の波が見えてくる。"])
}

extension DailyFortune {
    func text(for category: FortuneCategory) -> String? {
       texts[category]
    }
}
