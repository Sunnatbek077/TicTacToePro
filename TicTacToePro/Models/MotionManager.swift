//
//  MotionManager.swift
//  TicTacToePro
//
//  Created by Sunnatbek on 15/01/26.
//

import Combine
#if os(iOS)
import CoreMotion
#endif

class MotionManager: ObservableObject {
    #if os(iOS)
    private var motionManager = CMMotionManager()
    #endif
    
    @Published var x: Double = 0
    @Published var y: Double = 0
    
    init() {
        #if os(iOS)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let data = data else { return }
            self?.x = data.gravity.x
            self?.y = data.gravity.y
        }
        #else
        print("DeviceMotion tvOS-da ishlamaydi")
        #endif
    }
}
