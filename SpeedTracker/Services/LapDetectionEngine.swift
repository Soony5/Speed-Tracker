import Foundation
import CoreLocation
import Combine
import AudioToolbox

public final class LapDetectionEngine: ObservableObject {
    public static let shared = LapDetectionEngine()
    
    @Published public var activeCircuit: Circuit?
    @Published public var isRecording: Bool = false
    @Published public var hasPassedStart: Bool = false
    @Published public var hasFinished: Bool = false
    
    @Published public var elapsedTimeSeconds: Double = 0.0
    @Published public var currentSpeedKmh: Double = 0.0
    @Published public var maxSpeedKmh: Double = 0.0
    @Published public var currentDistanceMeters: Double = 0.0
    
    @Published public var nextCheckpointIndex: Int = 0
    @Published public var recordedSplits: [SectorSplit] = []
    
    private var telemetryBuffer: [TelemetryPoint] = []
    private var timerSubscription: AnyCancellable?
    private var startTime: Date?
    private var lastSectorTime: Date?
    private var lastLocation: CLLocation?
    
    public var onSessionCompleted: ((RunSession) -> Void)?
    
    private init() {}
    
    public func startFreeRun() {
        resetState()
        activeCircuit = nil
        isRecording = true
        hasPassedStart = true
        startTime = Date()
        startTimer()
        triggerHaptic()
    }
    
    public func armCircuit(_ circuit: Circuit) {
        resetState()
        activeCircuit = circuit
        isRecording = true
        hasPassedStart = false
        triggerHaptic()
        // Il timer partirà automaticamente appena l'utente oltrepassa il geofence di partenza
    }
    
    public func stopRun(save: Bool = true) {
        isRecording = false
        stopTimer()
        triggerHaptic()
        
        if save && !telemetryBuffer.isEmpty {
            let session = finalizeSession()
            onSessionCompleted?(session)
        }
        resetState()
    }
    
    public func processLocationUpdate(_ location: CLLocation, currentAccelG: Double) {
        guard isRecording else { return }
        
        let speedKmh = max(0.0, location.speed * 3.6)
        currentSpeedKmh = speedKmh
        if speedKmh > maxSpeedKmh {
            maxSpeedKmh = speedKmh
            AppSharedDefaults.shared.maxSpeedKmh = maxSpeedKmh
        }
        
        if let last = lastLocation {
            currentDistanceMeters += location.distance(from: last)
        }
        lastLocation = location
        
        let point = TelemetryPoint(
            timestamp: location.timestamp,
            coordinate: CoordinatePoint(clCoordinate: location.coordinate),
            speedKmh: speedKmh,
            accelerationG: currentAccelG,
            altitude: location.altitude
        )
        
        // Modalità circuito con trigger geofence dinamico
        if let circuit = activeCircuit {
            let currentCoord = CoordinatePoint(clCoordinate: location.coordinate)
            let userRadius = UserDefaults.standard.double(forKey: "speed_tracker_gps_radius")
            let triggerRadius = userRadius > 0 ? userRadius : 25.0
            
            if !hasPassedStart {
                // Controllo passaggio linea di partenza
                let distToStart = currentCoord.distance(to: circuit.startPoint)
                if distToStart <= triggerRadius {
                    hasPassedStart = true
                    startTime = Date()
                    lastSectorTime = startTime
                    startTimer()
                    triggerHaptic()
                }
            } else {
                // Abbiamo avviato il giro: registriamo il buffer
                telemetryBuffer.append(point)
                
                // Controllo checkpoint intermedi
                if nextCheckpointIndex < circuit.checkpoints.count {
                    let nextCp = circuit.checkpoints[nextCheckpointIndex]
                    let distToCp = currentCoord.distance(to: nextCp.coordinate)
                    let cpRadius = nextCp.triggerRadiusMeters > 0 ? nextCp.triggerRadiusMeters : triggerRadius
                    
                    if distToCp <= cpRadius {
                        let now = Date()
                        let splitTime = now.timeIntervalSince(lastSectorTime ?? (startTime ?? now))
                        let cumulative = now.timeIntervalSince(startTime ?? now)
                        
                        let split = SectorSplit(
                            checkpointId: nextCp.id,
                            checkpointName: nextCp.name,
                            sectorIndex: nextCheckpointIndex + 1,
                            splitTimeSeconds: splitTime,
                            cumulativeTimeSeconds: cumulative,
                            exitSpeedKmh: speedKmh
                        )
                        recordedSplits.append(split)
                        lastSectorTime = now
                        nextCheckpointIndex += 1
                        triggerHaptic()
                    }
                }
                
                // Controllo arrivo
                let targetFinish = circuit.circuitType == .loop ? circuit.startPoint : circuit.finishPoint
                let distToFinish = currentCoord.distance(to: targetFinish)
                
                // Se circuito chiuso, assicurati di non triggerare subito alla partenza
                let minElapsedToTriggerFinish: Double = circuit.circuitType == .loop ? 8.0 : 0.0
                if distToFinish <= triggerRadius && elapsedTimeSeconds > minElapsedToTriggerFinish {
                    // Se tutti i checkpoint sono passati (o non ce ne sono)
                    if nextCheckpointIndex >= circuit.checkpoints.count {
                        hasFinished = true
                        stopRun(save: true)
                    }
                }
            }
        } else {
            // Corsa libera
            telemetryBuffer.append(point)
        }
    }
    
    private func triggerHaptic() {
        if UserDefaults.standard.bool(forKey: "speed_tracker_haptic_feedback") {
            AudioServicesPlaySystemSound(1519) // Actuate `Peek` haptic standard
        }
    }
    
    private func startTimer() {
        timerSubscription = Timer.publish(every: 0.05, on: .main, in: .common) // 20Hz update timer per visualizzazione fluida
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.startTime else { return }
                self.elapsedTimeSeconds = Date().timeIntervalSince(start)
            }
    }
    
    private func stopTimer() {
        timerSubscription?.cancel()
        timerSubscription = nil
    }
    
    private func resetState() {
        stopTimer()
        hasPassedStart = false
        hasFinished = false
        elapsedTimeSeconds = 0.0
        currentDistanceMeters = 0.0
        maxSpeedKmh = 0.0
        nextCheckpointIndex = 0
        recordedSplits.removeAll()
        telemetryBuffer.removeAll()
        startTime = nil
        lastSectorTime = nil
        lastLocation = nil
    }
    
    private func finalizeSession() -> RunSession {
        let avgSpeed: Double
        if !telemetryBuffer.isEmpty {
            let totalSpeed = telemetryBuffer.reduce(0.0) { $0 + $1.speedKmh }
            avgSpeed = totalSpeed / Double(telemetryBuffer.count)
        } else {
            avgSpeed = 0.0
        }
        
        let maxG = telemetryBuffer.map(\.accelerationG).max() ?? 0.0
        
        let session = RunSession(
            name: activeCircuit != nil ? "Giro su \(activeCircuit!.name)" : "Corsa libera",
            circuitId: activeCircuit?.id,
            circuitName: activeCircuit?.name,
            date: Date(),
            totalDurationSeconds: elapsedTimeSeconds,
            maxSpeedKmh: maxSpeedKmh,
            averageSpeedKmh: avgSpeed,
            maxAccelerationG: maxG,
            totalDistanceMeters: currentDistanceMeters,
            sectorSplits: recordedSplits,
            telemetryPoints: telemetryBuffer
        )
        return session
    }
}
