import XCTest
@testable import Nyonda_

@MainActor
final class AppStateStoreTests: XCTestCase {
    private var isolatedDefaults: IsolatedDefaults!
    private let calendar = testCalendar(timeZoneIdentifier: "Asia/Tokyo")
    private lazy var now = testDate(2026, 11, 3, 12, 0, calendar: calendar)

    override func setUp() {
        super.setUp()
        isolatedDefaults = IsolatedDefaults()
    }

    override func tearDown() {
        isolatedDefaults.remove()
        isolatedDefaults = nil
        super.tearDown()
    }

    private func makeStore(now: Date? = nil) -> AppStateStore {
        let currentDate = now ?? self.now
        return AppStateStore(
            defaults: isolatedDefaults.defaults,
            calendar: calendar,
            now: { currentDate }
        )
    }

    func testNoPersistedDateMeansMedicineNotTakenToday() {
        XCTAssertFalse(makeStore().hasTakenMedicineToday)
    }

    func testMarkingMedicinePersistsSuppliedDate() {
        let date = testDate(2026, 11, 3, 9, 15, calendar: calendar)
        let store = makeStore()

        XCTAssertTrue(store.markMedicineTaken(at: date))
        XCTAssertEqual(
            isolatedDefaults.defaults.object(forKey: "appstate.lastTakenDate") as? Date,
            date
        )
    }

    func testMarkingTwiceInOneAppDaySucceedsOnlyOnce() {
        let store = makeStore()
        let first = testDate(2026, 11, 3, 8, 0, calendar: calendar)
        let second = testDate(2026, 11, 3, 22, 0, calendar: calendar)

        XCTAssertTrue(store.markMedicineTaken(at: first))
        XCTAssertFalse(store.markMedicineTaken(at: second))
    }

    func testDatesAcrossMidnightBeforeRolloverAreSameAppDay() {
        let store = makeStore()
        let first = testDate(2026, 11, 2, 23, 30, calendar: calendar)
        let second = testDate(2026, 11, 3, 5, 30, calendar: calendar)

        XCTAssertTrue(store.markMedicineTaken(at: first))
        XCTAssertFalse(store.markMedicineTaken(at: second))
    }

    func testMarkingAfterRolloverSucceedsAgain() {
        let store = makeStore()
        let beforeRollover = testDate(2026, 11, 3, 5, 30, calendar: calendar)
        let afterRollover = testDate(2026, 11, 3, 6, 0, calendar: calendar)

        XCTAssertTrue(store.markMedicineTaken(at: beforeRollover))
        XCTAssertTrue(store.markMedicineTaken(at: afterRollover))
    }

    func testUndoSucceedsAndClearsPersistedState() {
        let store = makeStore()
        XCTAssertTrue(store.markMedicineTaken(at: now))

        XCTAssertTrue(store.undoMedicineTakenToday())
        XCTAssertNil(store.lastTakenDate)
        XCTAssertNil(isolatedDefaults.defaults.object(forKey: "appstate.lastTakenDate"))
    }

    func testUndoWhenNothingWasTakenTodayReturnsFalse() {
        let yesterday = testDate(2026, 11, 2, 8, 0, calendar: calendar)
        isolatedDefaults.defaults.set(yesterday, forKey: "appstate.lastTakenDate")
        let store = makeStore()

        XCTAssertFalse(store.undoMedicineTakenToday())
        XCTAssertEqual(store.lastTakenDate, yesterday)
    }

    func testLegacyDateMigratesToNewKeyAndRemovesOldKey() {
        let legacyDate = testDate(2026, 11, 3, 9, 0, calendar: calendar)
        isolatedDefaults.defaults.set(legacyDate, forKey: "lastTakenDate")

        let store = makeStore()

        XCTAssertEqual(store.lastTakenDate, legacyDate)
        XCTAssertEqual(
            isolatedDefaults.defaults.object(forKey: "appstate.lastTakenDate") as? Date,
            legacyDate
        )
        XCTAssertNil(isolatedDefaults.defaults.object(forKey: "lastTakenDate"))
    }
}
