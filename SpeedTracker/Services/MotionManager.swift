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
    // Componente longitudinale (avanti/frenata)
    @Published public var longitudinalG: Double = 0.0
    // Componente laterale (curva sx/dx)
    @Published public var lateralG: Double = 0.0
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
        
        // Frequenza ultra-reattiva a 50Hz (ogni 20ms) per campionamento sportivo
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // userAcceleration rimuove la componente della forza gravitazionale costante di 1G verso terra
            let x = motion.userAcceleration.x
            let y = motion.userAcceleration.y
            let z = motion.userAcceleration.z
            
            // Grandezza del vettore di accelerazione netta (in G)
            let magnitudeG = sqrt(x * x + y * y + z * z)
            
            // Filtro reattivo adattivo: se l'accelerazione cambia rapidamente (staccata o apertura gas),
            // segui istantaneamente (alpha 0.8), altrimenti smorza le vibrazioni del telaio/strada (alpha 0.4)
            let diff = abs(magnitudeG - self.currentAccelerationG)
            let alpha = diff > 0.15 ? 0.80 : 0.40
            
            let smoothedG = (magnitudeG * alpha) + (self.currentAccelerationG * (1.0 - alpha))
            
            self.longitudinalG = y // asse Y del dispositivo corrisponde ad accelerazione/decelerazione
            self.lateralG = x      // asse X corrisponde a forze centrifughe laterali
            self.currentAccelerationG = smoothedG < 0.01 ? 0.0 : smoothedG
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
