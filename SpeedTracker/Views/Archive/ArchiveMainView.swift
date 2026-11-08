import SwiftUI

public enum ArchiveTab: String, CaseIterable {
    case circuits = "Tutti i Circuiti"
    case runs = "Corse Recenti"
}

public struct ArchiveMainView: View {
    @ObservedObject var storage = DataStorage.shared
    @State private var selectedSegment: ArchiveTab = .circuits
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // TOP BAR CON MINI HUD & SEGMENTED PICKER
                    HStack {
                        MiniSpeedHUD()
                        
                        Spacer()
                        
                        Picker("Archivio", selection: $selectedSegment) {
                            ForEach(ArchiveTab.allCases, id: \.self) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 210)
                        .padding(4)
                        .liquidGlass(cornerRadius: 16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // CONTENUTO
                    ScrollView {
                        VStack(spacing: 14) {
                            if selectedSegment == .circuits {
                                circuitsList
                            } else {
                                runsList
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("Archivio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Lista Circuiti
    private var circuitsList: some View {
        VStack(spacing: 12) {
            if storage.circuits.isEmpty {
                emptyPlaceholder(text: "Nessun circuito salvato. Creane uno dalla mappa!")
            } else {
                ForEach(storage.circuits) { circuit in
                    NavigationLink(destination: CircuitDetailView(circuit: circuit)) {
                        LiquidGlassCard(cornerRadius: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(circuit.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text(circuit.circuitType.rawValue)
                                            .font(.caption2.bold())
                                            .foregroundColor(.cyan)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                HStack(spacing: 16) {
                                    Label(String(format: "%.2f km", circuit.distanceMeters / 1000.0), systemImage: "point.bottomleft.forward.to.point.topright.scurvepath")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    if let best = circuit.bestLapTimeSeconds {
                                        Label(formatTime(best), systemImage: "trophy.fill")
                                            .font(.caption.bold())
                                            .foregroundColor(.yellow)
                                    } else {
                                        Label("Nessun record", systemImage: "clock")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Lista Corse
    private var runsList: some View {
        VStack(spacing: 12) {
            if storage.runSessions.isEmpty {
                emptyPlaceholder(text: "Nessuna corsa completata.")
            } else {
                ForEach(storage.runSessions) { session in
                    NavigationLink(destination: RunDetailView(session: session)) {
                        LiquidGlassCard(cornerRadius: 18) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(session.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 8) {
                                        Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        
                                        if let cName = session.circuitName {
                                            Text("• \(cName)")
                                                .font(.caption2.bold())
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(formatTime(session.totalDurationSeconds))
                                        .font(.system(size: 16, weight: .black, design: .monospaced))
                                        .foregroundColor(.cyan)
                                    Text(String(format: "Max: %.0f km/h", session.maxSpeedKmh))
                                        .font(.caption2.bold())
                                        .foregroundColor(.orange)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 6)
                            }
                            .padding(16)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func emptyPlaceholder(text: String) -> some View {
        LiquidGlassCard(cornerRadius: 18) {
            VStack(spacing: 10) {
                Image(systemName: "tray.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, millis)
    }
}
