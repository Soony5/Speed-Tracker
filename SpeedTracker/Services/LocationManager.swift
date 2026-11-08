import Foundation
import CoreLocation
import Combine

public final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published public var currentCoordinate: CLLocationCoordinate2D?
    @Published public var currentSpeedKmh: Double = 0.0
    @Published public var heading: Double = 0.0
    @Published public var isAuthorized: Bool = false
    @Published public var accuracy: Double = 0.0
    
    // Callback stream per la registrazione della telemetria attiva
    public var onLocationUpdate: ((CLLocation) -> Void)?
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = false // se abilitato nei permessi
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
        
        currentCoordinate = latest.coordinate
        accuracy = latest.horizontalAccuracy
        
        // CLLocation.speed è in metri al secondo. Se negativo (< 0), velocità non valida/disponibile
        if latest.speed >= 0 {
            let kmh = latest.speed * 3.6
            // Applica un leggero smoothing se la velocità è quasi ferma
            currentSpeedKmh = kmh < 1.0 ? 0.0 : kmh
        } else {
            currentSpeedKmh = 0.0
        }
        
        onLocationUpdate?(latest)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.trueHeading >= 0 {
            heading = newHeading.trueHeading
        } else {
            heading = newHeading.magneticHeading
        }
    }
}
