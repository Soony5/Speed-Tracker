import XCTest
import CoreLocation
@testable import SpeedTracker

final class SpeedTrackerTests: XCTestCase {
    
    func testCoordinateDistanceCalculation() {
        // Milano Duomo
        let duomo = CoordinatePoint(latitude: 45.4642, longitude: 9.1900)
        // Milano Stazione Centrale (~2.7 km)
        let centrale = CoordinatePoint(latitude: 45.4853, longitude: 9.2045)
        
        let dist = duomo.distance(to: centrale)
        XCTAssertGreaterThan(dist, 2300.0, "La distanza calcolata deve essere maggiore di 2.3km")
        XCTAssertLessThan(dist, 3000.0, "La distanza calcolata deve essere minore di 3.0km")
    }
    
    func testSpeedColorGradient() {
        let minSpeed: Double = 0.0
        let maxSpeed: Double = 100.0
        
        // Verifica che le funzioni colore non crashino e rispondano con valori coerenti
        let slowColor = SpeedColorHelper.color(for: 0.0, minSpeed: minSpeed, maxSpeed: maxSpeed)
        let midColor = SpeedColorHelper.color(for: 50.0, minSpeed: minSpeed, maxSpeed: maxSpeed)
        let fastColor = SpeedColorHelper.color(for: 100.0, minSpeed: minSpeed, maxSpeed: maxSpeed)
        
        XCTAssertNotNil(slowColor)
        XCTAssertNotNil(midColor)
        XCTAssertNotNil(fastColor)
    }
    
    func testCircuitModelIntegrity() {
        let start = CoordinatePoint(latitude: 45.6200, longitude: 9.2810)
        let finish = CoordinatePoint(latitude: 45.6200, longitude: 9.2810)
        let cp1 = Checkpoint(name: "Curva 1", order: 1, coordinate: CoordinatePoint(latitude: 45.6230, longitude: 9.2840))
        
        let circuit = Circuit(
            name: "Autodromo Test",
            notes: "Test circuit",
            circuitType: .loop,
            startPoint: start,
            finishPoint: finish,
            checkpoints: [cp1],
            roadPathPoints: [start, cp1.coordinate, finish],
            distanceMeters: 5000,
            estimatedTimeSeconds: 120.0
        )
        
        XCTAssertEqual(circuit.name, "Autodromo Test")
        XCTAssertEqual(circuit.checkpoints.count, 1)
        XCTAssertEqual(circuit.circuitType, .loop)
    }
    
    func testLapEngineFreeRunSession() {
        let engine = LapDetectionEngine.shared
        engine.startFreeRun()
        XCTAssertTrue(engine.isRecording)
        XCTAssertTrue(engine.hasPassedStart)
        
        // Simula rilevamento posizione a 60 km/h (16.66 m/s)
        let loc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0, longitude: 9.0),
            altitude: 100,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 16.66,
            timestamp: Date()
        )
        engine.processLocationUpdate(loc, currentAccelG: 0.25)
        
        XCTAssertGreaterThanOrEqual(engine.currentSpeedKmh, 59.0)
        XCTAssertGreaterThanOrEqual(engine.maxSpeedKmh, 59.0)
        
        engine.stopRun(save: false)
        XCTAssertFalse(engine.isRecording)
    }
    
    func testAppSharedDefaultsAndWidgetEntry() {
        let defaults = AppSharedDefaults.shared
        defaults.lastSpeedKmh = 120.5
        defaults.lastAccelG = 0.95
        defaults.maxSpeedKmh = 180.0
        defaults.accelUnit = "G"
        defaults.activeCircuitName = "Monza Eni Circuit"
        
        XCTAssertEqual(defaults.lastSpeedKmh, 120.5)
        XCTAssertEqual(defaults.lastAccelG, 0.95)
        XCTAssertEqual(defaults.maxSpeedKmh, 180.0)
        XCTAssertEqual(defaults.activeCircuitName, "Monza Eni Circuit")
        
        let entry = TelemetryWidgetEntry(
            speedKmh: defaults.lastSpeedKmh,
            maxSpeedKmh: defaults.maxSpeedKmh,
            accelerationG: defaults.lastAccelG,
            accelUnit: defaults.accelUnit,
            circuitName: defaults.activeCircuitName
        )
        XCTAssertEqual(entry.speedKmh, 120.5)
        XCTAssertEqual(entry.accelerationG, 0.95)
    }
}
