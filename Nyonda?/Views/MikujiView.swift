//
//  MikujiView.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/15.
//

import SwiftUI

struct MikujiView: View {
    private enum Phase {
        case waitingForShake
        case waitingForFlip
        case revealed
    }
    
    let onPullMikuji:() -> Void
    
    @State private var feedbackPlayer = AppFeedbackPlayer()
    @State private var phase:Phase = .waitingForShake
    @State private var revealedStickOffsetY:CGFloat = -120
    @State private var isRevealingStick = false
    private var stickOffsetY:CGFloat {
        return phase == .revealed ? revealedStickOffsetY : 0
    }
    
    @State private var motionReader = MikujiMotionReader()
    
    @State private var isShaking = false
    @State private var shakeStartedAt: Date?
    @State private var accumulatedShakeTime:TimeInterval = 0
    @State private var shakeIdletask: Task<Void, Never>?
    @State private var revealTask: Task<Void, Never>?
    
    private let requiredShakeTime: TimeInterval = 1.5
    private let shakeIdleTime:Duration = .milliseconds(500)

    var body: some View {
        VStack {
        if phase == .waitingForShake {
            if motionReader.isAvailable {
                PopInTxt("ふりふりしてにゃ!", size:40)
            } else {
                Button("タップしておみくじを引く") {
                    phase = .waitingForFlip
                    revealStick()
                }
            }
        } else if phase == .waitingForFlip {
            PopInTxt("さかさまにしてにゃ!", size:35)
        }
            
            Spacer()
                .frame(height:200)
            
            ZStack {
                mikujiImage("mikuji-top")
                mikujiImage("mikuji-stick")
                    .offset(y: stickOffsetY)
                mikujiImage("mikuji-box")
            }
            .aspectRatio(
                411.0 / 969.0,
                contentMode: .fit
            )
            .frame(width:150)
            .onChange(of: motionReader.shakeEventID) { oldValue, newValue in
                guard newValue > oldValue else { return }
                registerShakeActivity()
            }
            .onChange(of: motionReader.upsideDownEventID) { oldValue, newValue in
                guard newValue > oldValue else {return}
                revealStick()
            }
            .phaseAnimator([-1.0, 0.8, -0.7, 1.0]) { content, phaseValue in
                let movement = isShaking ? phaseValue : 0

                content
                    .offset(
                        x: movement * 6,
                        y: abs(movement) * -0.8
                    )
                    .rotationEffect(
                        .degrees(movement * 1.8),
                        anchor: .bottom
                    )
            } animation: { _ in
                .easeInOut(duration: 0.06)
            }
        }
        .onAppear {
            motionReader.start()
        }
        .onDisappear() {
            shakeIdletask?.cancel()
            revealTask?.cancel()
            feedbackPlayer.stop(.omikujiShake)
            motionReader.stop()
        }
    }

    private func mikujiImage(_ assetName: String) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
    }
    private func revealStick() {
        guard phase == .waitingForFlip,
              !isRevealingStick else {
            return
        }

        isRevealingStick = true
        revealTask?.cancel()
        revealTask = Task { @MainActor in
            
            shakeIdletask?.cancel()
            endShakeSession()
            
            withAnimation(.spring(response:0.35, dampingFraction: 0.55)) {
                phase = .revealed
            }
            feedbackPlayer.play(.omikujiStick)

            do {
                try await Task.sleep(for: .milliseconds(800))
            } catch {
                isRevealingStick = false
                return
            }

            isRevealingStick = false
            onPullMikuji()
        }
    }
    
    
    private func registerShakeActivity() {
        guard phase != .revealed else {
            return
        }
        
        if !isShaking {
            isShaking = true
            shakeStartedAt = .now
            feedbackPlayer.startLooping(.omikujiShake)
        }
        
        feedbackPlayer.impact(style:.heavy, intensity: 0.8)
        
        if phase == .waitingForShake, let shakeStartedAt {
            let currentShakeTime = accumulatedShakeTime + Date.now.timeIntervalSince(shakeStartedAt)
            if currentShakeTime >= requiredShakeTime {
                phase = .waitingForFlip
            }
        }
        
        shakeIdletask?.cancel()
        
        shakeIdletask = Task {@MainActor in
            do {
                try await Task.sleep(for: shakeIdleTime)
            } catch {
                return
            }
            endShakeSession()
            
        }
    }
    
    private func endShakeSession() {
        guard isShaking else {return}
        if let shakeStartedAt {
            accumulatedShakeTime += Date().timeIntervalSince(shakeStartedAt)
        }
        
        shakeStartedAt = nil
        isShaking = false
        feedbackPlayer.stop(.omikujiShake)
    }
    
}

#Preview {
    MikujiView(){}
}
