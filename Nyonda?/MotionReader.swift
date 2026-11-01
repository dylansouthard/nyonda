//
//  MotionReader.swift
//  Nyonda?
//
//  Created by Dylan Southard on 2026/08/15.
//

import Foundation
import CoreMotion
import Observation


@MainActor
@Observable
final class MikujiMotionReader {
    private let motionManager = CMMotionManager()
    
    private var samplingTask: Task<Void, Never>?
    
    private(set) var accelerationMagnitude = 0.0
    private(set) var gravityY = 0.0
    
    private(set) var shakeEventID = 0
    private(set) var upsideDownEventID = 0
    
    private let shakeThreshold = 1.1
    private let shakeCooldown = 0.25
    
    private let upsideDownThreshold = 0.75
    private let upsideDownReleaseTheshold = 0.4
    
    private var lastShakeTimestamp = -Double.infinity
    
    private var isUpsideDownLatched = false
    
    
    var isAvailable:Bool {
        motionManager.isDeviceMotionAvailable
    }
    
    func start() {
        guard isAvailable, !motionManager.isDeviceMotionActive else {return}
        
        motionManager.deviceMotionUpdateInterval = 1.0/60.0
        
        motionManager.startDeviceMotionUpdates()
        
        samplingTask = Task {[weak self] in
            while !Task.isCancelled {
                self?.readLatestSample()
                
                try? await Task.sleep(for: .microseconds(16))
            }
        }
    }
    
    func stop() {
        samplingTask?.cancel()
        samplingTask = nil
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func readLatestSample() {
        guard let motion = motionManager.deviceMotion else { return }
        let acceleration = motion.userAcceleration
        
        accelerationMagnitude = sqrt(acceleration.x * acceleration.x + acceleration.y * acceleration.y + acceleration.z * acceleration.z)
        
        gravityY = motion.gravity.y
        
        detectShake(timestamp: motion.timestamp)
        detectUpsideDown()
    }
    
    private func detectShake(timestamp: TimeInterval) {
        guard accelerationMagnitude >= shakeThreshold, timestamp - lastShakeTimestamp >= shakeCooldown else {return}
        lastShakeTimestamp = timestamp
        shakeEventID += 1
    }
    
    private func detectUpsideDown() {
        if gravityY >= upsideDownThreshold, !isUpsideDownLatched {
            isUpsideDownLatched = true
            upsideDownEventID += 1
        }
        
        if gravityY <= upsideDownReleaseTheshold {
            isUpsideDownLatched = false
        }
    }
    

}
