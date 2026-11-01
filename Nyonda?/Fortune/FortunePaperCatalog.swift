//
//  FortunePaperCatalog.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation

struct FortunePaperCatalog {
    private let imageNames: [CatTheme: [FortuneTone: [String]]] = [
        .ame:[
            .positive: ["ame_1", "ame_2", "ame_3", "ame_4"],
            .neutral: ["ame_5", "ame_6", "ame_7", "ame_8", "ame_9", "ame_10", "ame_11", "ame_12", "ame_13", "ame_14", "ame_15", "ame_16"],
            .negative: ["ame_17", "ame_18"]
        ],
        .sabi:[
            .positive: ["sabi_1", "sabi_2", "sabi_3", "sabi_4", "sabi_5"],
            .neutral: ["sabi_6", "sabi_7", "sabi_8", "sabi_9", "sabi_10", "sabi_11", "sabi_12", "sabi_13", "sabi_14", "sabi_15"],
            .negative: ["sabi_16", "sabi_17"]
        ]
    ]
    
    func options(for theme:CatTheme, tone: FortuneTone) -> [String] {
        imageNames[theme]?[tone] ?? []
    }
    
    func fallbackImageName(for theme: CatTheme) -> String {
        switch theme {
        case .ame:
            return "ame_10"

        case .sabi:
            return "sabi_8"
        }
    }
}
