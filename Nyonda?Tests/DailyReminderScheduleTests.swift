import XCTest
@testable import Nyonda_

final class DailyReminderScheduleTests: XCTestCase {
    private let calendar = testCalendar(timeZoneIdentifier: "Asia/Tokyo")

    func testBeforeSelectedTimeReturnsSameDay() throws {
        let schedule = DailyReminderSchedule(calendar: calendar)
        let now = testDate(2026, 11, 3, 8, 0, calendar: calendar)
        let expected = testDate(2026, 11, 3, 9, 30, calendar: calendar)
        let reminderTime = try XCTUnwrap(DailyReminderTime(hour: 9, minute: 30))

        XCTAssertEqual(
            schedule.nextFireDate(for: reminderTime, after: now),
            expected
        )
    }

    func testAfterSelectedTimeReturnsFollowingDay() throws {
        let schedule = DailyReminderSchedule(calendar: calendar)
        let now = testDate(2026, 11, 3, 10, 0, calendar: calendar)
        let expected = testDate(2026, 11, 4, 9, 30, calendar: calendar)
        let reminderTime = try XCTUnwrap(DailyReminderTime(hour: 9, minute: 30))

        XCTAssertEqual(
            schedule.nextFireDate(for: reminderTime, after: now),
            expected
        )
    }

    func testReturnedHourAndMinuteMatchReminderTime() throws {
        let schedule = DailyReminderSchedule(calendar: calendar)
        let now = testDate(2026, 11, 3, 8, 0, calendar: calendar)
        let reminderTime = try XCTUnwrap(DailyReminderTime(hour: 21, minute: 17))
        let fireDate = try XCTUnwrap(
            schedule.nextFireDate(for: reminderTime, after: now)
        )
        let components = calendar.dateComponents([.hour, .minute], from: fireDate)

        XCTAssertEqual(components.hour, 21)
        XCTAssertEqual(components.minute, 17)
    }

    func testScheduleAcrossDaylightSavingTransition() throws {
        let losAngeles = testCalendar(timeZoneIdentifier: "America/Los_Angeles")
        let schedule = DailyReminderSchedule(calendar: losAngeles)
        let beforeTransition = testDate(2026, 3, 7, 10, 0, calendar: losAngeles)
        let expected = testDate(2026, 3, 8, 9, 0, calendar: losAngeles)
        let reminderTime = try XCTUnwrap(DailyReminderTime(hour: 9, minute: 0))
        let fireDate = try XCTUnwrap(
            schedule.nextFireDate(
                for: reminderTime,
                after: beforeTransition
            )
        )

        XCTAssertEqual(fireDate, expected)
        XCTAssertEqual(fireDate.timeIntervalSince(beforeTransition), 22 * 60 * 60)
    }
}
