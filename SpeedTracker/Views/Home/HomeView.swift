import SwiftUI

public struct HomeView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var motionManager = MotionManager.shared
    @ObservedObject var lapEngine = LapDetectionEngine.shared
    @ObservedObject var storage = DataStorage.shared
    
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var selectedCircuitForRun: Circuit? = nil
    
    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background scuro sportivo
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.06, blue: 0.09),
                        Color(red: 0.08, green: 0.10, blue: 0.16)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // TACHIMETRO GRANDE NATIVO CON EFFETTO LIQUID GLASS
                        tachometerSection
                        
                        // CONTROLLO SESSIONE / CRONOMETRO IN CORSO
                        sessionControlCard
                        
                        // QUICK ACTION: CREA CIRCUITO
                        createCircuitShortcutCard
                        
                        // CORSE RECENTI
                        recentRunsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("SpeedTracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsSheet()
            }
        }
    }
    
    // MARK: - Tachimetro & Accelerazione
    private var tachometerSection: some View {
        LiquidGlassCard(cornerRadius: 32) {
            VStack(spacing: 6) {
                Text("VELOCITÀ ISTANTANEA")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundColor(.cyan.opacity(0.8))
                    .padding(.top, 24)
                
                // Velocità in grande
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", locationManager.currentSpeedKmh))
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                    
                    Text("km/h")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                }
                
                // Accelerazione istantanea più piccola sotto
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.and.down.and.sparkles")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("ACCELERAZIONE:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.2f %@", motionManager.displayAcceleration, motionManager.selectedUnit.label))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Controllo Corsa / Live Session
    private var sessionControlCard: some View {
        LiquidGlassCard(cornerRadius: 22) {
            VStack(spacing: 16) {
                if lapEngine.isRecording {
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(lapEngine.hasPassedStart ? Color.green : Color.yellow)
                                .frame(width: 10, height: 10)
                            
                            Text(lapEngine.hasPassedStart ? "SESSIONE IN CORSO" : "IN ATTESA DELLO START LINE...")
                                .font(.caption.bold())
                                .foregroundColor(lapEngine.hasPassedStart ? .green : .yellow)
                            
                            Spacer()
                            
                            if let circuit = lapEngine.activeCircuit {
                                Text(circuit.name)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("TEMPO")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                Text(formatTime(lapEngine.elapsedTimeSeconds))
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("VEL. MAX")
                                    .font(.caption2.bold())
                                    .foregroundColor(.gray)
                                Text(String(format: "%.1f km/h", lapEngine.maxSpeedKmh))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    Button {
                        lapEngine.stopRun(save: true)
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Termina e Salva Corsa")
                        }
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                } else {
                    // Selezione o Avvio Corsa
                    VStack(spacing: 14) {
                        HStack {
                            Image(systemName: "flag.checkered.2.crossed")
                                .foregroundColor(.cyan)
                            Text("Pronto per scendere in pista?")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button {
                                lapEngine.startFreeRun()
                            } label: {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Corsa Libera")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.cyan.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            if !storage.circuits.isEmpty {
                                Menu {
                                    ForEach(storage.circuits) { circuit in
                                        Button(circuit.name) {
                                            lapEngine.armCircuit(circuit)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "map.fill")
                                        Text("Scegli Circuito")
                                    }
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                }
            }
            .padding(18)
        }
    }
    
    // MARK: - Shortcut Creazione Circuito
    private var createCircuitShortcutCard: some View {
        Button {
            selectedTab = 1 // Passa alla tab Mappa per aprire il creator
        } label: {
            LiquidGlassCard(cornerRadius: 18) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Crea Nuovo Circuito")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Aperto o Chiuso con tracciamento strade live")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Ultime Corse
    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CORSE RECENTI")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
                Spacer()
                Button("Vedi tutte") {
                    selectedTab = 2 // Tab Archivio
                }
                .font(.caption.bold())
                .foregroundColor(.cyan)
            }
            .padding(.horizontal, 4)
            
            if storage.runSessions.isEmpty {
                LiquidGlassCard(cornerRadius: 16) {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 28))
                                .foregroundColor(.gray)
                            Text("Nessuna corsa ancora registrata")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                }
            } else {
                ForEach(storage.runSessions.prefix(3)) { session in
                    LiquidGlassCard(cornerRadius: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
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
                        }
                        .padding(16)
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
