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
    private let alarmService: AlarmService
    private let notificationService:NotificationService
    private(set) var reminderMode: ReminderMode
    private(set) var lastTakenDate: Date?
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
    
    init() {
        let reminderStore = ReminderStore()
        self.reminderStore = reminderStore
        self.alarmService = AlarmService()
        self.notificationService = NotificationService()
        self.reminderMode = reminderStore.reminderMode
        self.selectedTime = reminderStore.selectedTime ?? Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now) ?? .now
        self.isEnabled = reminderStore.isEnabled
        self.lastTakenDate = reminderStore.lastTakenDate
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
        guard isEnabled, let nextScheduledDate else {
            return false
        }
        let selectedTime = DailyReminderTime(from: date)
        let scheduledTime = DailyReminderTime(from: nextScheduledDate)
        
        return selectedTime != scheduledTime
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
    
    func enableDailyReminder() async {
        await withReminderOperation {
            modeChangeError = nil
            let succeeded = await activeService.enable(at:selectedReminderTime)
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
    func updateReminderTime(to newTime: Date) async -> Bool {
        await withReminderOperation {
            modeChangeError = nil
            guard isEnabled else { return false }
            guard needsReminderTimeUpdate(for: newTime) else { return true }

            let newReminderTime = DailyReminderTime(from: newTime)
            let succeeded = await activeService.updateTime(to: newReminderTime)
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
            await activeService.updateTime(to: selectedReminderTime)
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
