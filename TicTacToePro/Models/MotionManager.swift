//
//  MotionManager.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 15/01/26.
//

import CoreMotion
import Combine

class MotionManager: ObservableObject {
    private var motionManager = CMMotionManager()
    @Published var x: Double = 0
    @Published var y: Double = 0
    
    init() {
        // Ma'lumot yangilanish tezligi (60 FPS uchun)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let data = data else { return }
            // Gravity orqali telefon qiyaligini olamiz
            self?.x = data.gravity.x
            self?.y = data.gravity.y
        }
    }
}
