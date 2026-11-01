//
//  CatTheme.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import Foundation
enum CatTheme: String, CaseIterable, Codable, Hashable {
    case ame
    case sabi

    var iconName: String {
        "\(rawValue)-icn"
    }

    var closedImageName: String {
        "\(rawValue)-closed"
    }

    var openImageName: String {
        "\(rawValue)-open"
    }
}
