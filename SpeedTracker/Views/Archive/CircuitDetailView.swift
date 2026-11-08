import SwiftUI
import MapKit

public struct CircuitDetailView: View {
    public let circuit: Circuit
    @ObservedObject var lapEngine = LapDetectionEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var position: MapCameraPosition = .automatic
    
    public init(circuit: Circuit) {
        self.circuit = circuit
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // MAPPA TRACCIATO
                    Map(position: $position) {
                        Annotation("START", coordinate: circuit.startPoint.clCoordinate) {
                            Circle().fill(Color.green).frame(width: 20, height: 20)
                        }
                        
                        ForEach(circuit.checkpoints) { cp in
                            Annotation(cp.name, coordinate: cp.coordinate.clCoordinate) {
                                Circle().fill(Color.yellow).frame(width: 16, height: 16)
                            }
                        }
                        
                        if circuit.roadPathPoints.count >= 2 {
                            MapPolyline(coordinates: circuit.roadPathPoints.map(\.clCoordinate))
                                .stroke(Color.cyan, lineWidth: 5)
                        }
                    }
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    
                    // BOTTONE AVVIA SESSIONE SU QUESTO CIRCUITO
                    Button {
                        lapEngine.armCircuit(circuit)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "flag.checkered")
                            Text("Seleziona e Scendi in Pista")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.cyan, .white], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .cyan.opacity(0.3), radius: 10, y: 5)
                    }
                    
                    // SCHEDA DETTAGLI CIRCUITO
                    LiquidGlassCard(cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("DATI CIRCUITO")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                            
                            HStack {
                                Text("Tipologia")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(circuit.circuitType.rawValue)
                                    .foregroundColor(.white).bold()
                            }
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Lunghezza Totale")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(String(format: "%.2f km", circuit.distanceMeters / 1000.0))
                                    .foregroundColor(.white).bold()
                            }
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Tempo Stimato")
                                    .foregroundColor(.gray)
                                Spacer()
                                Text(formatTime(circuit.estimatedTimeSeconds))
                                    .foregroundColor(.cyan).bold()
                            }
                            Divider().background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Miglior Giro (Record)")
                                    .foregroundColor(.gray)
                                Spacer()
                                if let best = circuit.bestLapTimeSeconds {
                                    Text(formatTime(best))
                                        .foregroundColor(.green).bold()
                                } else {
                                    Text("Nessun record")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if !circuit.notes.isEmpty {
                                Divider().background(Color.white.opacity(0.1))
                                Text("Note:")
                                    .font(.caption.bold())
                                    .foregroundColor(.gray)
                                Text(circuit.notes)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(18)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(circuit.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        let millis = Int((seconds.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, millis)
    }
}
