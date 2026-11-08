import SwiftUI

public struct SpeedColorHelper {
    // Calcola il colore gradiente da verde (lento) -> giallo -> rosso (veloce)
    public static func color(for speed: Double, minSpeed: Double, maxSpeed: Double) -> Color {
        guard maxSpeed > minSpeed else { return .green }
        let fraction = max(0.0, min(1.0, (speed - minSpeed) / (maxSpeed - minSpeed)))
        
        if fraction < 0.5 {
            // Da Verde (0.0) a Giallo (0.5)
            let localF = fraction / 0.5
            return Color(red: localF, green: 1.0, blue: 0.1)
        } else {
            // Da Giallo (0.5) a Rosso (1.0)
            let localF = (fraction - 0.5) / 0.5
            return Color(red: 1.0, green: 1.0 - localF, blue: 0.1)
        }
    }
}
