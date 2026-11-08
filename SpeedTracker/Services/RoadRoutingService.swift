import Foundation
import CoreLocation
import MapKit

public final class RoadRoutingService {
    public static let shared = RoadRoutingService()
    
    private init() {}
    
    // Calcola il percorso stradale effettivo tra due punti usando le API native di Apple MKDirections
    public func calculateRoadRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) async -> (coordinates: [CoordinatePoint], distanceMeters: Double, expectedTimeSeconds: Double)? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            guard let route = response.routes.first else { return nil }
            
            // Estrazione coordinate della polyline
            let pointCount = route.polyline.pointCount
            var polylineCoords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            route.polyline.getCoordinates(&polylineCoords, range: NSRange(location: 0, length: pointCount))
            
            let points = polylineCoords.map { CoordinatePoint(clCoordinate: $0) }
            return (coordinates: points, distanceMeters: route.distance, expectedTimeSeconds: route.expectedTravelTime)
        } catch {
            print("MKDirections fallita, fallback su linea retta: \(error)")
            // Fallback su interpolazione lineare se offline o in pista chiusa non mappata
            let p1 = CoordinatePoint(clCoordinate: source)
            let p2 = CoordinatePoint(clCoordinate: destination)
            let dist = p1.distance(to: p2)
            let estTime = (dist / 25.0) // stima a ~90 km/h di media
            return (coordinates: [p1, p2], distanceMeters: dist, expectedTimeSeconds: estTime)
        }
    }
}
