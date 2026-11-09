import Foundation
import CoreLocation
import Combine

public struct SpeedSample {
    public let timestamp: Date
    public let speedKmh: Double
    public let accuracy: Double
    
    public init(timestamp: Date, speedKmh: Double, accuracy: Double) {
        self.timestamp = timestamp
        self.speedKmh = speedKmh
        self.accuracy = accuracy
    }
}

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published public var currentCoordinate: CLLocationCoordinate2D?
    @Published public var currentSpeedKmh: Double = 0.0
    @Published public var rawSpeedKmh: Double = 0.0
    @Published public var heading: Double = 0.0
    @Published public var isAuthorized: Bool = false
    @Published public var accuracy: Double = 0.0
    @Published public var speedAccuracy: Double = 0.0
    
    // Ultima posizione valida memorizzata per calcolo fallback differenziale
    private var lastValidLocation: CLLocation?
    private var recentSpeedSamples: [SpeedSample] = []
    
    // Callback stream per la registrazione della telemetria attiva
    public var onLocationUpdate: ((CLLocation) -> Void)?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        // Massima frequenza e sensibilità GPS: nessun filtro di distanza e modalità navigazione attiva
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    public func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            isAuthorized = true
            manager.startUpdatingLocation()
        default:
            isAuthorized = false
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        
        // Ignora rilevamenti obsoleti più vecchi di 3 secondi (es. cache GPS)
        let age = abs(latest.timestamp.timeIntervalSinceNow)
        if age > 3.0 {
            return
        }
        
        currentCoordinate = latest.coordinate
        accuracy = latest.horizontalAccuracy
        speedAccuracy = latest.speedAccuracy
        
        var calculatedSpeedKmh: Double = 0.0
        
        // 1. Lettura diretta da chipset GPS Doppler (CLLocation.speed è in m/s)
        if latest.speed >= 0.0 {
            calculatedSpeedKmh = latest.speed * 3.6
        } else if let prev = lastValidLocation {
            // 2. Fallback istantaneo ad altissima reattività: delta distanza su delta tempo
            let dt = latest.timestamp.timeIntervalSince(prev.timestamp)
            if dt > 0.05 && dt < 2.5 {
                let distMeters = latest.distance(from: prev)
                let derivedSpeedMs = distMeters / dt
                calculatedSpeedKmh = derivedSpeedMs * 3.6
            }
        }
        
        lastValidLocation = latest
        rawSpeedKmh = calculatedSpeedKmh
        
        // 3. Filtro reattivo con pesi esponenziali: reattività immediata in accelerazione/frenata
        let filteredSpeed = updateResponsiveSpeed(newSpeedKmh: calculatedSpeedKmh, at: latest.timestamp, accuracy: latest.horizontalAccuracy)
        
        // Se la velocità è inferiore a 0.5 km/h con telefono fermo, azzera per evitare micro-deriva
        currentSpeedKmh = filteredSpeed < 0.5 ? 0.0 : filteredSpeed
        
        // Sincronizza i dati per il widget di telemetria
        AppSharedDefaults.shared.lastSpeedKmh = currentSpeedKmh
        AppSharedDefaults.shared.lastUpdated = Date()
        
        onLocationUpdate?(latest)
    }
    
    private func updateResponsiveSpeed(newSpeedKmh: Double, at timestamp: Date, accuracy: Double) -> Double {
        // Mantieni campioni degli ultimi 1.0 secondi per smoothing dinamico
        recentSpeedSamples.append(SpeedSample(timestamp: timestamp, speedKmh: newSpeedKmh, accuracy: accuracy))
        recentSpeedSamples.removeAll { timestamp.timeIntervalSince($0.timestamp) > 1.0 }
        
        guard !recentSpeedSamples.isEmpty else { return newSpeedKmh }
        
        // Se c'è una forte variazione di velocità (> 5 km/h di scarto), dai precedenza istantanea all'ultimo dato per massima reattività
        let speedDiff = abs(newSpeedKmh - currentSpeedKmh)
        let alpha: Double
        if speedDiff > 10.0 {
            alpha = 0.90 // Reazione quasi istantanea a scatto/staccata violenta
        } else if speedDiff > 4.0 {
            alpha = 0.75 // Rapido inseguimento
        } else {
            alpha = 0.60 // Smoothing fine su velocità di crociera
        }
        
        return (alpha * newSpeedKmh) + ((1.0 - alpha) * currentSpeedKmh)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
        } else {
            heading = newHeading.magneticHeading
        }
    }
}
