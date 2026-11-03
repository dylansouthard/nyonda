//
//  ReminderController.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/08.
//

import Foundation
import Observation

@MainActor
@Observable
final class ReminderController {
    
    private let reminderStore: ReminderStore
    private let alarmService: any ReminderDeliveryService
    private let notificationService: any ReminderDeliveryService
    private let calendar: Calendar
    private let now: () -> Date
    private(set) var reminderMode: ReminderMode
    private var activeService: any ReminderDeliveryService {
        service(for: reminderMode)
    }
    
    private(set) var isEnabled = false
    private(set) var isPerformingOperation = false
    

    
    var selectedTime: Date {
        didSet {
            reminderStore.saveSelectedTime(selectedTime)
        }
    }
    
    private var selectedReminderTime: DailyReminderTime {
        DailyReminderTime(from: selectedTime)
    }
    
    var nextScheduledDate: Date? {activeService.nextScheduledDate}
    
    private(set) var modeChangeError: String?
    var errorMessage: String? {modeChangeError ?? activeService.errorMessage}
    
    convenience init() {
        let reminderStore = ReminderStore()
        self.init(
            reminderStore: reminderStore,
            alarmService: AlarmService(),
            notificationService: NotificationService()
        )
    }

    init(
        reminderStore: ReminderStore,
        alarmService: any ReminderDeliveryService,
        notificationService: any ReminderDeliveryService,
        calendar: Calendar = .autoupdatingCurrent,
        now: @escaping () -> Date = { .now }
    ) {
        self.reminderStore = reminderStore
        self.alarmService = alarmService
        self.notificationService = notificationService
        self.calendar = calendar
        self.now = now
        self.reminderMode = reminderStore.reminderMode
        let currentDate = now()
        self.selectedTime = reminderStore.selectedTime
            ?? calendar.date(bySettingHour: 23, minute: 0, second: 0, of: currentDate)
            ?? currentDate
        self.isEnabled = reminderStore.isEnabled
    }
    
    private func service(for mode: ReminderMode) -> any ReminderDeliveryService {
        switch mode {
        case .alarm:
            alarmService
        case .notification:
            notificationService
        }
    }
    
    func needsReminderTimeUpdate(for date: Date) -> Bool {
        DailyReminderTime(from: date) != selectedReminderTime
    }
    
    @discardableResult
    func changeReminderMode(to newMode:ReminderMode) async -> Bool {
        guard newMode != reminderMode else {return true}
        return await withReminderOperation {
            let oldService = service(for: reminderMode)
            let newService = service(for: newMode)
            
            modeChangeError = nil
            
            guard isEnabled else {
                reminderMode = newMode
                reminderStore.saveReminderMode(newMode)
                return true
            }
            
            let didEnableNewService = await newService.enable(at: selectedReminderTime)
            guard didEnableNewService else {
                modeChangeError = newService.errorMessage ?? "Could not enable the selected reminder mode."
                return false
            }
            
            let didDisableOldService = await oldService.disable()
            guard didDisableOldService else {
                await newService.disable()
                modeChangeError = oldService.errorMessage ?? "Could not disable previous reminder mode"
                return false
            }
            
            reminderMode = newMode
            reminderStore.saveReminderMode(newMode)
            return true
        } ?? false
    }
    
    func enableDailyReminder(medicineTakenToday: Bool) async {
        await withReminderOperation {
            modeChangeError = nil
            let succeeded: Bool

            if medicineTakenToday {
                let currentDate = now()
                let scheduleStartDate = AppDay.nextRollover(
                    after: currentDate,
                    calendar: calendar
                ) ?? currentDate

                succeeded = await activeService.updateTime(
                    to: selectedReminderTime,
                    after: scheduleStartDate
                )
            } else {
                succeeded = await activeService.enable(
                    at: selectedReminderTime
                )
            }

            guard succeeded else {return}
            setEnabled(true)
        }
        
    }
    
    func disableDailyReminder() async {
        
        await withReminderOperation {
            modeChangeError = nil
            let succeeded = await activeService.disable()
            guard succeeded else {return}
            setEnabled(false)
        }
    }
    
    @discardableResult
    func updateReminderTime(
        to newTime: Date,
        medicineTakenToday: Bool
    ) async -> Bool {
        await withReminderOperation {
            modeChangeError = nil
            guard isEnabled else { return false }
            guard needsReminderTimeUpdate(for: newTime) else { return true }

            let newReminderTime = DailyReminderTime(from: newTime)
            let scheduleStartDate: Date

            let currentDate = now()
            if medicineTakenToday {
                scheduleStartDate = AppDay.nextRollover(
                    after: currentDate,
                    calendar: calendar
                ) ?? currentDate
            } else {
                scheduleStartDate = currentDate
            }

            let succeeded = await activeService.updateTime(
                to: newReminderTime,
                after: scheduleStartDate
            )
            guard succeeded else { return false }

            selectedTime = newTime
            return true
        } ?? false
    }
    
    @discardableResult
    func skipToday() async -> Bool {
        let result = await withReminderOperation {
            modeChangeError = nil

            guard isEnabled else {
                return true
            }

            guard let nextScheduledDate else {
                modeChangeError = "次のリマインダーが見つかりませんでした。"
                return false
            }

            guard AppDay.isToday(
                nextScheduledDate,
                calendar: .autoupdatingCurrent
            ) else {
                return true
            }

            let succeeded = await activeService.skipToday(
                at: selectedReminderTime
            )

            if !succeeded {
                modeChangeError = activeService.errorMessage
                    ?? "今日のリマインダーをスキップできませんでした。"
            }

            return succeeded
        }

        guard let result else {
            modeChangeError = "別のリマインダー操作が進行中です。もう一度お試しください。"
            return false
        }

        return result
    }
    
    func restoreTodayReminderIfPossible() async {
        await withReminderOperation {
            guard isEnabled else {return}
            modeChangeError = nil
            await activeService.updateTime(
                to: selectedReminderTime,
                after: now()
            )
        }
    }
    
    func reconcileReminderState() async {
        await withReminderOperation {
            await activeService.reconcile()
            
            if isEnabled {
                await activeService.enable(at: selectedReminderTime)
            } else {
                await activeService.disable()
            }
        }
        
    }
    
    func observeReminderUpdates() async {
        await activeService.monitorUpdates()
    }
    
    private func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        reminderStore.saveIsEnabled(enabled)
    }
    
    @discardableResult
    private func withReminderOperation<Result>(_ operation: @MainActor () async -> Result) async -> Result?{
        guard !isPerformingOperation else {return nil}
        isPerformingOperation = true
        defer {isPerformingOperation = false}
        
        return await operation()
    }
}
