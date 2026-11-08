import Foundation
import CoreLocation

public struct CoordinatePoint: Codable, Equatable, Hashable {
    public var latitude: Double
    public var longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(clCoordinate: CLLocationCoordinate2D) {
        self.latitude = clCoordinate.latitude
        self.longitude = clCoordinate.longitude
    }
    
    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public func distance(to other: CoordinatePoint) -> Double {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return loc1.distance(from: loc2)
    }
}

public struct Checkpoint: Identifiable, Codable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var order: Int
    public var coordinate: CoordinatePoint
    public var triggerRadiusMeters: Double
    
    public init(id: UUID = UUID(), name: String, order: Int, coordinate: CoordinatePoint, triggerRadiusMeters: Double = 25.0) {
        self.id = id
        self.name = name
        self.order = order
        self.coordinate = coordinate
        self.triggerRadiusMeters = triggerRadiusMeters
    }
}

public enum CircuitType: String, Codable, CaseIterable {
    case loop = "Anello (Chiuso)"
    case pointToPoint = "Aperto (Punto A -> B)"
}

public struct Circuit: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var notes: String
    public var circuitType: CircuitType
    public var startPoint: CoordinatePoint
    public var finishPoint: CoordinatePoint
    public var checkpoints: [Checkpoint]
    public var roadPathPoints: [CoordinatePoint] // Coordinate dettagliate della strada calcolata
    public var distanceMeters: Double
    public var estimatedTimeSeconds: Double
    public var bestLapTimeSeconds: Double?
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        circuitType: CircuitType = .loop,
        startPoint: CoordinatePoint,
        finishPoint: CoordinatePoint,
        checkpoints: [Checkpoint] = [],
        roadPathPoints: [CoordinatePoint] = [],
        distanceMeters: Double = 0.0,
        estimatedTimeSeconds: Double = 0.0,
        bestLapTimeSeconds: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.circuitType = circuitType
        self.startPoint = startPoint
        self.finishPoint = finishPoint
        self.checkpoints = checkpoints
        self.roadPathPoints = roadPathPoints
        self.distanceMeters = distanceMeters
        self.estimatedTimeSeconds = estimatedTimeSeconds
        self.bestLapTimeSeconds = bestLapTimeSeconds
        self.createdAt = createdAt
    }
}

