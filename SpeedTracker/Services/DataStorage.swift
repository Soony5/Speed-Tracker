import Foundation
import Combine

public final class DataStorage: ObservableObject {
    public static let shared = DataStorage()
    
    @Published public var circuits: [Circuit] = []
    @Published public var runSessions: [RunSession] = []
    
    private let circuitsKey = "speed_tracker_saved_circuits_v1"
    private let runsKey = "speed_tracker_saved_runs_v1"
    
    private init() {
        loadData()
        if circuits.isEmpty {
            loadDefaultSampleData()
        }
    }
    
    public func saveCircuit(_ circuit: Circuit) {
        if let idx = circuits.firstIndex(where: { $0.id == circuit.id }) {
            circuits[idx] = circuit
        } else {
            circuits.insert(circuit, at: 0)
        }
        persistCircuits()
    }
    
    public func deleteCircuit(_ circuit: Circuit) {
        circuits.removeAll(where: { $0.id == circuit.id })
        persistCircuits()
    }
    
    public func saveRunSession(_ session: RunSession) {
        runSessions.insert(session, at: 0)
        persistRuns()
        
        // Aggiorna eventuale record del circuito
        if let circuitId = session.circuitId, let idx = circuits.firstIndex(where: { $0.id == circuitId }) {
            let currentBest = circuits[idx].bestLapTimeSeconds
            if currentBest == nil || session.totalDurationSeconds < currentBest! {
                circuits[idx].bestLapTimeSeconds = session.totalDurationSeconds
                persistCircuits()
            }
        }
    }
    
    public func deleteRunSession(_ session: RunSession) {
        runSessions.removeAll(where: { $0.id == session.id })
        persistRuns()
    }
    
    private func persistCircuits() {
        do {
            let data = try JSONEncoder().encode(circuits)
            UserDefaults.standard.set(data, forKey: circuitsKey)
        } catch {
            print("Errore nel salvataggio dei circuiti: \(error)")
        }
    }
    
    private func persistRuns() {
        do {
            let data = try JSONEncoder().encode(runSessions)
            UserDefaults.standard.set(data, forKey: runsKey)
        } catch {
            print("Errore nel salvataggio delle corse: \(error)")
        }
    }
    
    private func loadData() {
        if let circuitData = UserDefaults.standard.data(forKey: circuitsKey) {
            if let decoded = try? JSONDecoder().decode([Circuit].self, from: circuitData) {
                self.circuits = decoded
            }
        }
        
        if let runData = UserDefaults.standard.data(forKey: runsKey) {
            if let decoded = try? JSONDecoder().decode([RunSession].self, from: runData) {
                self.runSessions = decoded
            }
        }
    }
    
    private func loadDefaultSampleData() {
        // Circuito dimostrativo (Monza - Variante Ascari demo)
        let start = CoordinatePoint(latitude: 45.6200, longitude: 9.2810)
        let finish = CoordinatePoint(latitude: 45.6200, longitude: 9.2810)
        let cp1 = Checkpoint(name: "Curva Grande", order: 1, coordinate: CoordinatePoint(latitude: 45.6230, longitude: 9.2840))
        let cp2 = Checkpoint(name: "Variante Ascari", order: 2, coordinate: CoordinatePoint(latitude: 45.6280, longitude: 9.2890))
        
        let demoCircuit = Circuit(
            name: "Circuito Demo Monza (Ascari)",
            notes: "Test track con curve veloci e staccate",
            circuitType: .loop,
            startPoint: start,
            finishPoint: finish,
            checkpoints: [cp1, cp2],
            roadPathPoints: [start, cp1.coordinate, cp2.coordinate, finish],
            distanceMeters: 5793,
            estimatedTimeSeconds: 105.0,
            bestLapTimeSeconds: 102.4
        )
        self.circuits = [demoCircuit]
        persistCircuits()
    }
}
