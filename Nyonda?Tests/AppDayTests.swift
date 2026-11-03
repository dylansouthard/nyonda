import XCTest
@testable import Nyonda_

final class AppDayTests: XCTestCase {
    private let calendar = testCalendar(timeZoneIdentifier: "Asia/Tokyo")

    func testRolloverSeparatesFiveFiftyNineFromSix() {
        let before = testDate(2026, 11, 3, 5, 59, 59, calendar: calendar)
        let boundary = testDate(2026, 11, 3, 6, 0, 0, calendar: calendar)

        XCTAssertFalse(AppDay.isSameDay(before, boundary, calendar: calendar))
    }

    func testDatesAcrossMidnightBeforeSixBelongToSameAppDay() {
        let beforeMidnight = testDate(2026, 11, 2, 23, 30, calendar: calendar)
        let afterMidnight = testDate(2026, 11, 3, 2, 0, calendar: calendar)

        XCTAssertTrue(AppDay.isSameDay(beforeMidnight, afterMidnight, calendar: calendar))
    }

    func testIsTodayAroundRollover() {
        let now = testDate(2026, 11, 3, 5, 45, calendar: calendar)
        let previousEvening = testDate(2026, 11, 2, 22, 0, calendar: calendar)
        let afterRollover = testDate(2026, 11, 3, 6, 0, calendar: calendar)

        XCTAssertTrue(AppDay.isToday(previousEvening, relativeTo: now, calendar: calendar))
        XCTAssertFalse(AppDay.isToday(afterRollover, relativeTo: now, calendar: calendar))
    }

    func testNextRolloverReturnsUpcomingBoundary() {
        let now = testDate(2026, 11, 3, 5, 45, calendar: calendar)
        let expected = testDate(2026, 11, 3, 6, 0, calendar: calendar)

        XCTAssertEqual(AppDay.nextRollover(after: now, calendar: calendar), expected)
    }

    func testNextRolloverAfterSixReturnsFollowingDay() {
        let now = testDate(2026, 11, 3, 6, 0, 1, calendar: calendar)
        let expected = testDate(2026, 11, 4, 6, 0, calendar: calendar)

        XCTAssertEqual(AppDay.nextRollover(after: now, calendar: calendar), expected)
    }
}
