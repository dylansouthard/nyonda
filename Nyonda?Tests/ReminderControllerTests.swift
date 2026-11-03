import XCTest
@testable import Nyonda_

@MainActor
final class ReminderControllerTests: XCTestCase {
    private var isolatedDefaults: IsolatedDefaults!
    private var callLog: NSMutableArray!
    private var alarmService: FakeReminderService!
    private var notificationService: FakeReminderService!
    private let calendar = testCalendar(timeZoneIdentifier: "Asia/Tokyo")
    private lazy var now = testDate(2026, 11, 3, 12, 0, calendar: calendar)

    override func setUp() {
        super.setUp()
        isolatedDefaults = IsolatedDefaults()
        callLog = NSMutableArray()
        alarmService = FakeReminderService(name: "alarm", calendar: calendar, callLog: callLog)
        notificationService = FakeReminderService(name: "notification", calendar: calendar, callLog: callLog)
    }

    override func tearDown() {
        isolatedDefaults.remove()
        isolatedDefaults = nil
        callLog = nil
        alarmService = nil
        notificationService = nil
        super.tearDown()
    }

    private func makeController(
        enabled: Bool,
        mode: ReminderMode = .alarm,
        selectedHour: Int = 23,
        now: Date? = nil
    ) -> ReminderController {
        let store = ReminderStore(defaults: isolatedDefaults.defaults)
        store.saveIsEnabled(enabled)
        store.saveReminderMode(mode)
        store.saveSelectedTime(testDate(2026, 11, 3, selectedHour, 0, calendar: calendar))
        let currentDate = now ?? self.now
        return ReminderController(
            reminderStore: store,
            alarmService: alarmService,
            notificationService: notificationService,
            calendar: calendar,
            now: { currentDate }
        )
    }

    func testSuccessfulModeSwitchEnablesNewThenDisablesOldAndPersists() async {
        let controller = makeController(enabled: true)

        let succeeded = await controller.changeReminderMode(to: .notification)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(callLog as? [String], ["notification.enable", "alarm.disable"])
        XCTAssertEqual(controller.reminderMode, .notification)
        XCTAssertEqual(ReminderStore(defaults: isolatedDefaults.defaults).reminderMode, .notification)
    }

    func testNewServiceEnableFailureLeavesOldServiceAndModeUntouched() async {
        notificationService.enableResult = false
        notificationService.errorMessage = "new service failed"
        let controller = makeController(enabled: true)

        let succeeded = await controller.changeReminderMode(to: .notification)
        XCTAssertFalse(succeeded)
        XCTAssertEqual(callLog as? [String], ["notification.enable"])
        XCTAssertEqual(controller.reminderMode, .alarm)
        XCTAssertEqual(controller.errorMessage, "new service failed")
    }

    func testOldServiceDisableFailureRollsBackNewService() async {
        alarmService.disableResult = false
        alarmService.errorMessage = "old service failed"
        let controller = makeController(enabled: true)

        let succeeded = await controller.changeReminderMode(to: .notification)
        XCTAssertFalse(succeeded)
        XCTAssertEqual(
            callLog as? [String],
            ["notification.enable", "alarm.disable", "notification.disable"]
        )
        XCTAssertEqual(controller.reminderMode, .alarm)
        XCTAssertEqual(controller.errorMessage, "old service failed")
    }

    func testDisabledModeChangeDoesNotScheduleEitherService() async {
        let controller = makeController(enabled: false)

        let succeeded = await controller.changeReminderMode(to: .notification)
        XCTAssertTrue(succeeded)
        XCTAssertEqual(callLog.count, 0)
        XCTAssertEqual(controller.reminderMode, .notification)
    }

    func testEnablingBeforeMedicineTakenUsesNormalEnablePath() async {
        let controller = makeController(enabled: false)

        await controller.enableDailyReminder(medicineTakenToday: false)

        XCTAssertEqual(callLog as? [String], ["alarm.enable"])
        XCTAssertTrue(controller.isEnabled)
    }

    func testEnablingAfterMedicineTakenStartsAtNextRollover() async {
        let controller = makeController(enabled: false)
        let expectedBoundary = testDate(2026, 11, 4, 6, 0, calendar: calendar)

        await controller.enableDailyReminder(medicineTakenToday: true)

        XCTAssertEqual(callLog as? [String], ["alarm.update"])
        XCTAssertEqual(alarmService.updateArguments.first?.1, expectedBoundary)
        XCTAssertTrue(controller.isEnabled)
    }

    func testFailedEnableAfterMedicineTakenLeavesReminderDisabled() async {
        alarmService.updateResult = false
        let controller = makeController(enabled: false)

        await controller.enableDailyReminder(medicineTakenToday: true)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertFalse(ReminderStore(defaults: isolatedDefaults.defaults).isEnabled)
    }

    func testEnabledReconciliationReconcilesThenEnsuresActiveService() async {
        let controller = makeController(enabled: true)

        await controller.reconcileReminderState()

        XCTAssertEqual(callLog as? [String], ["alarm.reconcile", "alarm.enable"])
    }

    func testDisabledReconciliationDisablesActiveService() async {
        let controller = makeController(enabled: false)

        await controller.reconcileReminderState()

        XCTAssertEqual(callLog as? [String], ["alarm.reconcile", "alarm.disable"])
    }

    func testTimeUpdateBeforeMedicineTakenStartsAtCurrentMomentAndPersists() async {
        alarmService.nextScheduledDate = testDate(2026, 11, 3, 23, 0, calendar: calendar)
        let controller = makeController(enabled: true)
        let proposed = testDate(2026, 11, 3, 21, 30, calendar: calendar)

        let succeeded = await controller.updateReminderTime(
            to: proposed,
            medicineTakenToday: false
        )
        XCTAssertTrue(succeeded)
        XCTAssertEqual(alarmService.updateArguments.first?.1, now)
        XCTAssertEqual(controller.selectedTime, proposed)
        XCTAssertEqual(ReminderStore(defaults: isolatedDefaults.defaults).selectedTime, proposed)
    }

    func testTimeUpdateAfterMedicineTakenStartsAtNextRollover() async {
        alarmService.nextScheduledDate = testDate(2026, 11, 3, 23, 0, calendar: calendar)
        let controller = makeController(enabled: true)
        let proposed = testDate(2026, 11, 3, 21, 30, calendar: calendar)
        let expectedBoundary = testDate(2026, 11, 4, 6, 0, calendar: calendar)

        let succeeded = await controller.updateReminderTime(
            to: proposed,
            medicineTakenToday: true
        )
        XCTAssertTrue(succeeded)
        XCTAssertEqual(alarmService.updateArguments.first?.1, expectedBoundary)
    }

    func testFailedTimeUpdateLeavesCommittedTimeUnchanged() async {
        alarmService.updateResult = false
        alarmService.nextScheduledDate = testDate(2026, 11, 3, 23, 0, calendar: calendar)
        let controller = makeController(enabled: true)
        let original = controller.selectedTime
        let proposed = testDate(2026, 11, 3, 21, 30, calendar: calendar)

        let succeeded = await controller.updateReminderTime(
            to: proposed,
            medicineTakenToday: false
        )
        XCTAssertFalse(succeeded)
        XCTAssertEqual(controller.selectedTime, original)
        XCTAssertEqual(ReminderStore(defaults: isolatedDefaults.defaults).selectedTime, original)
    }

    func testTimeUpdateWithMatchingScheduledTimeDoesNotReschedule() async {
        alarmService.nextScheduledDate = testDate(2026, 11, 3, 23, 0, calendar: calendar)
        let controller = makeController(enabled: true, selectedHour: 23)

        let succeeded = await controller.updateReminderTime(
            to: controller.selectedTime,
            medicineTakenToday: false
        )

        XCTAssertTrue(succeeded)
        XCTAssertTrue(alarmService.updateArguments.isEmpty)
    }

    func testUndoBeforeSelectedTimeRestoresToday() async throws {
        let currentDate = testDate(2026, 11, 3, 20, 0, calendar: calendar)
        let controller = makeController(enabled: true, selectedHour: 23, now: currentDate)

        await controller.restoreTodayReminderIfPossible()

        let nextDate = try XCTUnwrap(alarmService.nextScheduledDate)
        XCTAssertEqual(nextDate, testDate(2026, 11, 3, 23, 0, calendar: calendar))
    }

    func testUndoAfterSelectedTimeRestoresFollowingDay() async throws {
        let currentDate = testDate(2026, 11, 3, 23, 30, calendar: calendar)
        let controller = makeController(enabled: true, selectedHour: 23, now: currentDate)

        await controller.restoreTodayReminderIfPossible()

        let nextDate = try XCTUnwrap(alarmService.nextScheduledDate)
        XCTAssertEqual(nextDate, testDate(2026, 11, 4, 23, 0, calendar: calendar))
    }
}
