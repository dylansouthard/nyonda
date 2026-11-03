//
//  AppFeedbackPlayer.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/10.
//

import Foundation
import AVFoundation
import UIKit

enum SoundEffect: String, CaseIterable, Hashable {
    case medicineTaken = "success"
    case omikujiShake = "omikuji_shake"
    case omikujiStick = "omikuji_stick"
    case paper = "paper"
    
    var fileExtension: String {
        "caf"
    }
    
    var filename: String {
        "\(rawValue).\(fileExtension)"
    }
}


@MainActor
final class AppFeedbackPlayer {
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    
    init() {
        configureAudioSession()
        prepareSounds()
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        } catch {
            print("Could not configure audio session: \(error)")
        }
    }
    
    private func prepareSounds() {
        for sound in SoundEffect.allCases {
            prepare(sound)
        }
    }
    
    private func prepare(_ sound: SoundEffect) {
        guard let soundURL = Bundle.main.url (
            forResource:sound.rawValue,
            withExtension: sound.fileExtension
        ) else {
            print("Could not find \(sound.filename)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.prepareToPlay()
            audioPlayers[sound] = player
        } catch {
            print("Could not prepare \(sound.filename): \(error)")
        }
    }
    
    func play(_ sound: SoundEffect) {
        guard let player = audioPlayers[sound] else {
            print("\(sound.filename) is not prepared")
            return
        }
        player.currentTime = 0
        player.play()
    }
    
    func startLooping(_ sound: SoundEffect) {
        guard let player = audioPlayers[sound] else {
            print("sound \(sound.filename) not prepared")
            return
        }
        
        if !player.isPlaying {
            player.currentTime = 0
            player.numberOfLoops = -1
            player.play()
        }
    }
    
    func stop(_ sound: SoundEffect) {
        guard let player = audioPlayers[sound] else {return}
        
        player.stop()
        player.currentTime = 0
        player.numberOfLoops = 0
    }
    
    func impact(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        intensity: CGFloat = 0.7
    ) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }
    
    func doubleImpact(
        style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        intensity: CGFloat = 0.8,
        spacing: Duration = .milliseconds(120)
    ) {
        let generator = UIImpactFeedbackGenerator(style:style)
        generator.prepare()
        generator.impactOccurred( intensity:intensity)
        
        Task {@MainActor in
            try? await Task.sleep(for: spacing)
            generator.prepare()
            generator.impactOccurred(intensity: intensity)
        }
        
    }
}
