//
//  AppDay.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/16.
//

import Foundation

enum AppDay {
    static let rolloverHour = 6

    static func isSameDay(
        _ firstDate: Date,
        _ secondDate: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let shiftedFirstDate = shifted(
            firstDate,
            calendar: calendar
        )

        let shiftedSecondDate = shifted(
            secondDate,
            calendar: calendar
        )

        return calendar.isDate(
            shiftedFirstDate,
            inSameDayAs: shiftedSecondDate
        )
    }

    static func isToday(
        _ date: Date,
        relativeTo now: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        isSameDay(
            date,
            now,
            calendar: calendar
        )
    }

    static func nextRollover(
        after date: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date? {
        calendar.nextDate(
            after: date,
            matching: DateComponents(
                hour: rolloverHour,
                minute: 0,
                second: 0
            ),
            matchingPolicy: .nextTime
        )
    }

    private static func shifted(
        _ date: Date,
        calendar: Calendar
    ) -> Date {
        guard let shiftedDate = calendar.date(
            byAdding: .hour,
            value: -rolloverHour,
            to: date
        ) else {
            assertionFailure("Could not calculate shifted app day.")
            return date
        }

        return shiftedDate
    }
}
