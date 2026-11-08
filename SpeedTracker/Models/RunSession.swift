import Foundation

public struct TelemetryPoint: Identifiable, Codable, Equatable {
    public var id: UUID
    public var timestamp: Date
    public var coordinate: CoordinatePoint
    public var speedKmh: Double
    public var accelerationG: Double
    public var altitude: Double?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        coordinate: CoordinatePoint,
        speedKmh: Double,
        accelerationG: Double,
        altitude: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.coordinate = coordinate
        self.speedKmh = speedKmh
        self.accelerationG = accelerationG
        self.altitude = altitude
    }
}

public struct SectorSplit: Identifiable, Codable, Equatable {
    public var id: UUID
    public var checkpointId: UUID
    public var checkpointName: String
    public var sectorIndex: Int
    public var splitTimeSeconds: Double // Tempo parziale del settore
    public var cumulativeTimeSeconds: Double // Tempo cumulativo dallo start
    public var exitSpeedKmh: Double
    
    public init(
        id: UUID = UUID(),
        checkpointId: UUID,
        checkpointName: String,
        sectorIndex: Int,
        splitTimeSeconds: Double,
        cumulativeTimeSeconds: Double,
        exitSpeedKmh: Double
    ) {
        self.id = id
        self.checkpointId = checkpointId
        self.checkpointName = checkpointName
        self.sectorIndex = sectorIndex
        self.splitTimeSeconds = splitTimeSeconds
        self.cumulativeTimeSeconds = cumulativeTimeSeconds
        self.exitSpeedKmh = exitSpeedKmh
    }
}

public struct RunSession: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var circuitId: UUID?
    public var circuitName: String?
    public var date: Date
    public var totalDurationSeconds: Double
    public var maxSpeedKmh: Double
    public var averageSpeedKmh: Double
    public var maxAccelerationG: Double
    public var totalDistanceMeters: Double
    public var sectorSplits: [SectorSplit]
    public var telemetryPoints: [TelemetryPoint]
    
    public init(
        id: UUID = UUID(),
        name: String = "",
        circuitId: UUID? = nil,
        circuitName: String? = nil,
        date: Date = Date(),
        totalDurationSeconds: Double = 0.0,
        maxSpeedKmh: Double = 0.0,
        averageSpeedKmh: Double = 0.0,
        maxAccelerationG: Double = 0.0,
        totalDistanceMeters: Double = 0.0,
        sectorSplits: [SectorSplit] = [],
        telemetryPoints: [TelemetryPoint] = []
    ) {
        self.id = id
        self.name = name.isEmpty ? "Corsa del \(date.formatted(date: .abbreviated, time: .shortened))" : name
        self.circuitId = circuitId
        self.circuitName = circuitName
        self.date = date
        self.totalDurationSeconds = totalDurationSeconds
        self.maxSpeedKmh = maxSpeedKmh
        self.averageSpeedKmh = averageSpeedKmh
        self.maxAccelerationG = maxAccelerationG
        self.totalDistanceMeters = totalDistanceMeters
        self.sectorSplits = sectorSplits
        self.telemetryPoints = telemetryPoints
    }
}

