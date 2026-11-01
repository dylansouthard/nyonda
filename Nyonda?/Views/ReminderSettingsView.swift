//
//  AlarmSettingsView.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/09.
//

import SwiftUI

struct ReminderSettingsView: View {
    @Bindable var reminderController: ReminderController
    @Environment(\.dismiss)
    private var dismiss
    
    
    var body: some View {
        NavigationStack {
            Form {
                alarmControlsSection
                alarmTimeSection
                scheduledAlarmSection
            }
            
            .navigationTitle("Alarm Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
            }
            
        }
        
    }
    
    
    private var alarmTimeSection: some View {
        Section("リマインダーの設定") {
            
            HStack {
                DatePicker(
                    selection:$reminderController.selectedTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("時間", systemImage: "clock")
                }
                .disabled(reminderController.isPerformingOperation || !reminderController.isEnabled)
                Divider()
                Button {
                    Task {
                        await reminderController.updateReminderTime()
                    }
                } label: { Text("OK") }
                    .disabled(!reminderController.needsReminderTimeUpdate || reminderController.isPerformingOperation || !reminderController.isEnabled)
            }
            Picker("リマインダー方法", selection: reminderModeBinding) {
                ForEach(ReminderMode.allCases) {mode in
                    Label (mode.title, systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .disabled(reminderController.isPerformingOperation)
        }
        }
    

    
    private var alarmControlsSection: some View {
        Section {
            Button {
                if reminderController.isEnabled {
                    Task {
                        await reminderController.disableDailyReminder()
                    }
                    
                } else {
                    Task {
                        await reminderController.enableDailyReminder()
                    }
                }
            } label: {
                Label(
                    reminderController.isEnabled
                        ? "リマインダーを無効にする"
                        : "リマインダーを有効にする",
                    systemImage: reminderController.isEnabled
                        ? "bell.slash"
                        : "alarm"
                )
            }
            .disabled(
                reminderController.isPerformingOperation
            )
        }
    }
    @ViewBuilder
    private var scheduledAlarmSection: some View {
        if let fireDate = reminderController.nextScheduledDate {
            Section("次のリマインダー") {
                Text(
                    fireDate,
                    format: .dateTime
                        .weekday(.wide)
                        .month(.abbreviated)
                        .day()
                        .hour()
                        .minute()
                )
            }
        }
    }
    
    private var reminderModeBinding: Binding<ReminderMode> {
        Binding(
            get: {reminderController.reminderMode},
            set: { newMode in
                Task {
                    await reminderController.changeReminderMode(to: newMode)
                }
            }
        )
    }
}

#Preview {
    ReminderSettingsView(reminderController: ReminderController())
}
