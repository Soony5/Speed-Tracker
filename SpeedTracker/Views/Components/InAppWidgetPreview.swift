import SwiftUI

// Widget preview e test in-app per simulare e visualizzare il Widget in chiaro/scuro
public struct InAppWidgetPreview: View {
    let speed: Double
    let accel: Double
    let maxSpeed: Double
    let circuitName: String?
    
    public init(speed: Double = 94.0, accel: Double = 0.88, maxSpeed: Double = 168.0, circuitName: String? = "Monza Eni Circuit") {
        self.speed = speed
        self.accel = accel
        self.maxSpeed = maxSpeed
        self.circuitName = circuitName
    }
    
    public var body: some View {
        SpeedTelemetryWidgetView(
            entry: TelemetryWidgetEntry(
                speedKmh: speed,
                maxSpeedKmh: maxSpeed,
                accelerationG: accel,
                accelUnit: "G",
                circuitName: circuitName
            ),
            isCompact: true
        )
        .frame(width: 160, height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}
