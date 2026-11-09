import WidgetKit
import SwiftUI

// MARK: - Modello Dati Telemetria per Widget
public struct TelemetryWidgetEntry: TimelineEntry {
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

// MARK: - Provider per Timeline WidgetKit
public struct SpeedWidgetProvider: TimelineProvider {
    public typealias Entry = TelemetryWidgetEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> TelemetryWidgetEntry {
        TelemetryWidgetEntry(speedKmh: 84.5, maxSpeedKmh: 142.0, accelerationG: 0.85, circuitName: "Monza Track")
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (TelemetryWidgetEntry) -> Void) {
        let entry = currentEntry()
        completion(entry)
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<TelemetryWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // Aggiorna regolarmente
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func currentEntry() -> TelemetryWidgetEntry {
        let defaults = AppSharedDefaults.shared
        return TelemetryWidgetEntry(
            date: Date(),
            speedKmh: defaults.lastSpeedKmh,
            maxSpeedKmh: defaults.maxSpeedKmh,
            accelerationG: defaults.lastAccelG,
            accelUnit: defaults.accelUnit,
            circuitName: defaults.activeCircuitName
        )
    }
}

// MARK: - Vista Widget in stile Liquid Glass Adattivo
public struct SpeedTelemetryWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    let entry: TelemetryWidgetEntry
    
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
                        .font(.system(size: family == .systemSmall ? 44 : 52, weight: .black, design: .rounded))
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
                    
                    if family != .systemSmall {
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

// MARK: - Dichiarazione del Widget
public struct SpeedTrackerWidget: Widget {
    public let kind: String = "SpeedTrackerWidget"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpeedWidgetProvider()) { entry in
            SpeedTelemetryWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("SpeedTracker Telemetria")
        .description("Visualizza istantaneamente velocità in km/h e accelerazione G sulla Home o schermata di blocco.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
