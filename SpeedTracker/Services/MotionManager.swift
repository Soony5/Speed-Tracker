import Foundation
import CoreMotion
import Combine

public enum AccelerationUnit: String, CaseIterable, Codable {
    case gForce = "G"
    case metersPerSecondSquared = "m/s²"
    
    public var label: String {
        return self.rawValue
    }
}

public final class MotionManager: ObservableObject {
    public static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    
    // Accelerazione pura istantanea in unità G
    @Published public var currentAccelerationG: Double = 0.0
    // Accelerazione convertita in base all'unità attiva
    @Published public var displayAcceleration: Double = 0.0
    @Published public var selectedUnit: AccelerationUnit = .gForce {
        didSet {
            UserDefaults.standard.set(selectedUnit.rawValue, forKey: "speed_tracker_accel_unit")
            updateDisplayAcceleration()
        }
    }
    
    private let standardGravity = 9.80665
    
    private init() {
        if let savedUnit = UserDefaults.standard.string(forKey: "speed_tracker_accel_unit"),
           let unit = AccelerationUnit(rawValue: savedUnit) {
            self.selectedUnit = unit
        }
        startMonitoring()
    }
    
    public func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0 // 30Hz per fluidità
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // userAcceleration rimuove la componente della forza gravitazionale costante
            let x = motion.userAcceleration.x
            let y = motion.userAcceleration.y
            let z = motion.userAcceleration.z
            
            // Grandezza del vettore di accelerazione netta (in G)
            let magnitudeG = sqrt(x * x + y * y + z * z)
            
            // Filtro passa-basso esponenziale per smorzare rumori di vibrazione
            let smoothedG = (self.currentAccelerationG * 0.8) + (magnitudeG * 0.2)
            self.currentAccelerationG = smoothedG < 0.02 ? 0.0 : smoothedG
            self.updateDisplayAcceleration()
        }
    }
    
    public func stopMonitoring() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    private func updateDisplayAcceleration() {
        switch selectedUnit {
        case .gForce:
            displayAcceleration = currentAccelerationG
        case .metersPerSecondSquared:
            displayAcceleration = currentAccelerationG * standardGravity
        }
    }
}

