import SwiftUI

// MARK: - Modello Dati Telemetria (condiviso con In-App Widget Preview)
public struct TelemetryWidgetEntry {
    public let date: Date
    public let speedKmh: Double
    public let maxSpeedKmh: Double
    public let accelerationG: Double
    public let accelUnit: String
    public let circuitName: String?
    
    public init(
        date: Date = Date(),
        speedKmh: Double = 0.0,
        maxSpeedKmh: Double = 0.0,
        accelerationG: Double = 0.0,
        accelUnit: String = "G",
        circuitName: String? = nil
    ) {
        self.date = date
        self.speedKmh = speedKmh
        self.maxSpeedKmh = maxSpeedKmh
        self.accelerationG = accelerationG
        self.accelUnit = accelUnit
        self.circuitName = circuitName
    }
}

// MARK: - Vista Widget in stile Liquid Glass Adattivo (usata in-app e dal widget)
public struct SpeedTelemetryWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    let entry: TelemetryWidgetEntry
    var isCompact: Bool = true // true = small widget size, false = medium
    
    public var body: some View {
        ZStack {
            // Sfondo dinamico Liquid Glass con gradiente sportivo
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.08, blue: 0.14),
                        Color(red: 0.12, green: 0.15, blue: 0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 1.0),
                        Color(red: 0.88, green: 0.92, blue: 0.97)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Effetto vetro smerigliato e riflessi al neon
            VStack(alignment: .leading, spacing: 6) {
                // Header badge
                HStack(spacing: 5) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.cyan)
                    Text(entry.circuitName ?? "TELEMETRIA")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundColor(.cyan)
                        .lineLimit(1)
                    Spacer()
                }
                
                Spacer()
                
                // Velocità istantanea grande
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.0f", entry.speedKmh))
                        .font(.system(size: isCompact ? 44 : 52, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark ? [.white, .white.opacity(0.9)] : [Color(red: 0.1, green: 0.12, blue: 0.2), Color(red: 0.2, green: 0.25, blue: 0.35)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("km/h")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                // Accelerazione sotto la velocità
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("ACCEL:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    Text(String(format: "%.2f %@", entry.accelerationG, entry.accelUnit))
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                    
                    if !isCompact {
                        Spacer()
                        Text("MAX: \(Int(entry.maxSpeedKmh)) km/h")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                .clipShape(Capsule())
            }
            .padding(14)
        }
    }
}
