//
//  ReminderMode.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/10/18.
//

import SwiftUI

enum ReminderMode: String, Codable, CaseIterable, Identifiable {
    case alarm
    case notification
    var id: Self { self }
}

extension ReminderMode {
    var title: LocalizedStringKey {
        switch self {
        case .alarm:
            "アラーム"
        case .notification:
            "通知"
        }
    }
    var systemImage: String {
        switch self {
        case .alarm:
            "alarm.fill"
        case .notification:
            "bell.badge.fill"
        }
    }
}


