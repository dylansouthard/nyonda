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
    @State private var presentedErrorMessage: String?
    @State private var draftTime: Date
    let medicineTakenToday: Bool
    
    init(
        reminderController: ReminderController,
        medicineTakenToday: Bool
    ) {
        self.reminderController = reminderController
        self.medicineTakenToday = medicineTakenToday
        _draftTime = State(initialValue: reminderController.selectedTime)
    }
    
    private var draftTimeMatchesScheduledTime: Bool {
        !reminderController.needsReminderTimeUpdate(for: draftTime)
    }
    
    private var isPresentingError: Binding<Bool> {
        Binding(
            get: {
                presentedErrorMessage != nil
            },
            set: {isPresented in
                if !isPresented {
                    presentedErrorMessage = nil
                }
            })
    }
    
    
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
            .onAppear {
                if let existingError = reminderController.errorMessage {
                    presentedErrorMessage = existingError
                }
            }
            .onChange(of: reminderController.errorMessage) {_, newError in
                guard let newError else {return}
                presentedErrorMessage = newError
            }
            .alert("エラー", isPresented: isPresentingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(presentedErrorMessage ?? "リマインダーを設定できませんでした。")
            }
            
        }
        
    }
    
    
    private var alarmTimeSection: some View {
        Section("リマインダーの設定") {
            
            HStack {
                DatePicker(
                    selection:$draftTime,
                    displayedComponents: .hourAndMinute
                ) {
                    Label("時間", systemImage: "clock")
                        .foregroundStyle(.primary)
                }
                .disabled(reminderController.isPerformingOperation || !reminderController.isEnabled)
                Divider()
                Button {
                    let proposedTime = draftTime

                    Task {
                        let succeeded = await reminderController.updateReminderTime(
                            to: proposedTime,
                            medicineTakenToday: medicineTakenToday
                        )

                        if !succeeded {
                            draftTime = reminderController.selectedTime
                        }
                    }
                } label: { Text("OK").foregroundColor(.btnTxt) }
                    .disabled(
                        draftTimeMatchesScheduledTime
                        || reminderController.isPerformingOperation
                        || !reminderController.isEnabled
                    )
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
                .foregroundColor(.btnTxt)
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
    ReminderSettingsView(
        reminderController: ReminderController(),
        medicineTakenToday: false
    )
}
