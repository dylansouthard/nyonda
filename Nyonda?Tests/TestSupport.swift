import Foundation
import XCTest
@testable import Nyonda_

func testCalendar(timeZoneIdentifier: String) -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US_POSIX")
    calendar.timeZone = TimeZone(identifier: timeZoneIdentifier)!
    return calendar
}

func testDate(
    _ year: Int,
    _ month: Int,
    _ day: Int,
    _ hour: Int,
    _ minute: Int = 0,
    _ second: Int = 0,
    calendar: Calendar
) -> Date {
    calendar.date(from: DateComponents(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second
    ))!
}

final class IsolatedDefaults {
    let suiteName = "NyondaTests.\(UUID().uuidString)"
    let defaults: UserDefaults

    init() {
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    func remove() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}

@MainActor
final class FakeReminderService: ReminderDeliveryService {
    let name: String
    let calendar: Calendar
    let callLog: NSMutableArray

    var nextScheduledDate: Date?
    var errorMessage: String?
    var enableResult = true
    var disableResult = true
    var updateResult = true
    var skipResult = true
    private(set) var updateArguments: [(DailyReminderTime, Date)] = []

    init(
        name: String,
        calendar: Calendar,
        callLog: NSMutableArray
    ) {
        self.name = name
        self.calendar = calendar
        self.callLog = callLog
    }

    func enable(at time: DailyReminderTime) async -> Bool {
        callLog.add("\(name).enable")
        return enableResult
    }

    func disable() async -> Bool {
        callLog.add("\(name).disable")
        return disableResult
    }

    func updateTime(
        to time: DailyReminderTime,
        after startDate: Date
    ) async -> Bool {
        callLog.add("\(name).update")
        updateArguments.append((time, startDate))
        if updateResult {
            nextScheduledDate = DailyReminderSchedule(calendar: calendar)
                .nextFireDate(for: time, after: startDate)
        }
        return updateResult
    }

    func skipToday(at time: DailyReminderTime) async -> Bool {
        callLog.add("\(name).skip")
        return skipResult
    }

    func reconcile() async {
        callLog.add("\(name).reconcile")
    }
}
