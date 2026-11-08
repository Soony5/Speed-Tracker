import SwiftUI
import MapKit

public struct RunDetailView: View {
    public let session: RunSession
    @ObservedObject var storage = DataStorage.shared
    
    @State private var position: MapCameraPosition = .automatic
    
    public init(session: RunSession) {
        self.session = session
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MAPPA COLOR-CODED CON VELOCITÀ DINAMICA
                    mapSection
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    // CARD STATISTICHE PRINCIPALI
                    statsGrid
                    
                    // INTERTEMPI / CHECKPOINTS (SE PRESENTI)
                    if !session.sectorSplits.isEmpty {
                        splitsSection
                    }
                    
                    // LINK INTERATTIVO AL CIRCUITO
                    if let circuitId = session.circuitId,
                       let circuit = storage.circuits.first(where: { $0.id == circuitId }) {
                        NavigationLink(destination: CircuitDetailView(circuit: circuit)) {
                            LiquidGlassCard(cornerRadius: 18) {
                                HStack {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .foregroundColor(.cyan)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Circuito Collegato")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(circuit.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(session.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Mappa con tracciato Color-Coded
    private var mapSection: some View {
        Map(position: $position) {
            // Disegna segmenti colorati in base alla velocità istantanea
            let pts = session.telemetryPoints
            if pts.count >= 2 {
                let minSpeed = pts.map(\.speedKmh).min() ?? 0.0
                let maxSpeed = pts.map(\.speedKmh).max() ?? 1.0
                
                // Disegna coppie di punti consecutivi
                ForEach(0..<(pts.count - 1), id: \.self) { i in
                    let p1 = pts[i]
                    let p2 = pts[i+1]
                    let segmentSpeed = (p1.speedKmh + p2.speedKmh) / 2.0
                    let color = SpeedColorHelper.color(for: segmentSpeed, minSpeed: minSpeed, maxSpeed: maxSpeed)
                    
                    MapPolyline(coordinates: [p1.coordinate.clCoordinate, p2.coordinate.clCoordinate])
                        .stroke(color, lineWidth: 5)
                }
                
                // Segnaposto Start
                Annotation("Start", coordinate: pts.first!.coordinate.clCoordinate) {
                    Circle().fill(Color.green).frame(width: 16, height: 16)
                }
                // Segnaposto Finish
                Annotation("Fine", coordinate: pts.last!.coordinate.clCoordinate) {
                    Circle().fill(Color.red).frame(width: 16, height: 16)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
    
    // MARK: - Statistiche
    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "TEMPO TOTALE", value: formatTime(session.totalDurationSeconds), icon: "stopwatch.fill", color: .cyan)
                StatCard(title: "DISTANZA", value: String(format: "%.2f km", session.totalDistanceMeters / 1000.0), icon: "road.lanes", color: .green)
            }
            HStack(spacing: 12) {
                StatCard(title: "VELOCITÀ MAX", value: String(format: "%.1f km/h", session.maxSpeedKmh), icon: "bolt.fill", color: .red)
                StatCard(title: "VELOCITÀ MEDIA", value: String(format: "%.1f km/h", session.averageSpeedKmh), icon: "gauge.with.needle.fill", color: .orange)
            }
        }
    }
    
    // MARK: - Split Tempi
    private var splitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("INTERTEMPI CHECKPOINT")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyan)
            
            LiquidGlassCard(cornerRadius: 18) {
                VStack(spacing: 0) {
                    ForEach(session.sectorSplits) { split in
                        HStack {
                            Text(split.checkpointName)
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(formatTime(split.splitTimeSeconds))
                                    .font(.system(size: 14, weight: .black, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Text(String(format: "Uscita: %.0f km/h", split.exitSpeedKmh))
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if split.id != session.sectorSplits.last?.id {
                            Divider().background(Color.white.opacity(0.1))
                        }
                    }
                }
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, millis)
    }
}

public struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    public var body: some View {
        LiquidGlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(title)
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.gray)
                }
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}

