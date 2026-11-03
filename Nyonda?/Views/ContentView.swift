//
//  ContentView.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/08.
//

import SwiftUI
import SwiftData

private extension AnyTransition {
    static var centerWipe: AnyTransition {
        .modifier(
            active: CenterWipeModifier(phaseIsIdentity: false),
            identity: CenterWipeModifier(phaseIsIdentity: true)
        )
    }

    struct CenterWipeModifier: ViewModifier {
        let phaseIsIdentity: Bool

        func body(content: Content) -> some View {
            content
                .mask {
                    Rectangle()
                        .scaleEffect(
                            x: 1,
                            y: phaseIsIdentity ? 1 : 0,
                            anchor: .center
                        )
                }
        }
    }
}

struct ContentView: View {
    private enum FortuneOverlayStage: Equatable {
        case hidden
        case mikuji
        case fortuneClosed
        case fortune
    }
    
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var fortuneOverlayStage: FortuneOverlayStage = .hidden
    @State private var reminderController = ReminderController()
    @State private var fortuneController = FortuneController()
    @State private var isShowingAlarmSettings = false
    @State private var isShowingReminderError = false
    @State private var reminderErrorMessage = ""
    @State private var appState = AppStateStore()
    private var isFortuneOverlayVisible: Bool {
        fortuneOverlayStage != .hidden
    }
    private struct ReminderTaskID: Equatable {
        let scenePhase: ScenePhase
        let reminderMode: ReminderMode
    }
    
    private var reminderTaskID: ReminderTaskID {
        ReminderTaskID(scenePhase: scenePhase, reminderMode: reminderController.reminderMode)
    }
    @AppStorage("catTheme")
    private var currentTheme: CatTheme = .ame

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing:32) {
                    CatView(
                        theme:currentTheme,
                        canMarkMedicineTaken: appState.canMarkMedicineTaken,
                        isBusy: reminderController.isPerformingOperation,
                        onSkipToday: {
                        Task {@MainActor in
                            let didMarkTaken = withAnimation{
                                appState.markMedicineTaken()
                            }
                            guard didMarkTaken else {return}
                            fortuneController.loadOrGenerateToday(for: currentTheme)

                            let didSkipReminder = await reminderController.skipToday()
                            if !didSkipReminder {
                                reminderErrorMessage = reminderController.errorMessage
                                    ?? "今日のリマインダーをスキップできませんでした。"
                                isShowingReminderError = true
                            }

                            do {
                                try await Task.sleep(for: .seconds(1))
                            } catch {
                                withAnimation(.easeIn(duration: 0.5)) {
                                    self.fortuneOverlayStage = .mikuji
                                }
                            }
                            self.fortuneOverlayStage = .mikuji
                        }
                    },
                        onUndoSkip: {
                            let didUndo = withAnimation {
                                appState.undoMedicineTakenToday()
                            }
                            guard didUndo else {return}
                            Task {
                                await reminderController.restoreTodayReminderIfPossible()
                            }
                        }
                    )
//                    Button("clear fortune") {
//                        fortuneController.store.clear()
//                    }
                    Picker("Cat theme", selection: $currentTheme) {
                        ForEach(CatTheme.allCases, id: \.self) { theme in
                            Image(theme.iconName)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .frame(width: 44, height: 34)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 100)
                    .controlSize(.large)
                    .transaction { transaction in
                        transaction.animation = nil
                    }
                    
                }
                .background(Color.bkgMain)
                .frame(maxWidth:.infinity, maxHeight: .infinity)
                .toolbar {
                    if fortuneController.hasFortuneToday {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                withAnimation(.easeIn(duration: 0.5)) {
                                    fortuneOverlayStage = .fortune
                                }
                            } label: {
                                Image("omikuji_icn")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            }
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            
                            isShowingAlarmSettings = true
                        } label: {
                            Image(systemName: "alarm")
                        }
                    }
                }
            }
            .blur(radius: isFortuneOverlayVisible ? 7 : 0)
            .allowsHitTesting(!isFortuneOverlayVisible)
            .sheet(isPresented: $isShowingAlarmSettings) {
                ReminderSettingsView(
                    reminderController: reminderController,
                    medicineTakenToday: appState.hasTakenMedicineToday
                )
                .presentationDetents([
                    .medium,
                    .large
                ])
                .presentationDragIndicator(.visible)
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else {
                    return
                }
                fortuneController.restoreToday()
            }
            .task(id: reminderTaskID) {
                guard scenePhase == .active else {return}
                await reminderController.reconcileReminderState()
                await reminderController.observeReminderUpdates()
            }
            if fortuneOverlayStage == .mikuji || fortuneOverlayStage == .fortuneClosed {

                MikujiView() {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        fortuneOverlayStage = .fortuneClosed
                    }
                }
                    .transition(
                        .opacity.combined(with:.scale(scale: 0.92))
                    )
                    .zIndex(2)
            }
            if fortuneOverlayStage == .fortuneClosed {
                    Image("omikuji_closed")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220)
                        .shadow(
                            color: .black.opacity(0.30),
                            radius: 12,
                            x: 0,
                            y: 8
                        )
                        .shadow(
                            color: .black.opacity(0.16),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                        .transition(
                            .scale(scale: 0)
                                .combined(with: .opacity)
                        )
                        .zIndex(3)
                        .onTapGesture {
                            withAnimation(.easeIn(duration: 1)) {
                                fortuneOverlayStage = .fortune
                            }
                        }
                }
            if let fortune = fortuneController.todayFortune, fortuneOverlayStage == .fortune {
                FortuneView(fortune) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        fortuneOverlayStage = .hidden
                    }
                }
                .transition(
                    .asymmetric(
                        insertion: .centerWipe,
                        removal: .opacity
                    )
                )
                .zIndex(3)
            }
        }
        .alert(
            "リマインダーを更新できませんでした",
            isPresented: $isShowingReminderError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(reminderErrorMessage)
        }
        
    }
    

}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

