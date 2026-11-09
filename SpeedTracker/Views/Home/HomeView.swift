import SwiftUI

public struct HomeView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var motionManager = MotionManager.shared
    @ObservedObject var lapEngine = LapDetectionEngine.shared
    @ObservedObject var storage = DataStorage.shared
    
    @Binding var selectedTab: Int
    @State private var showingSettings = false
    @State private var selectedCircuitForRun: Circuit? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    public init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background adattivo: Scuro sportivo o Chiaro dinamico
                Group {
                    if colorScheme == .dark {
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.06, blue: 0.09),
                                Color(red: 0.08, green: 0.10, blue: 0.16)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        LinearGradient(
                            colors: [
                                Color(red: 0.94, green: 0.95, blue: 0.98),
                                Color(red: 0.88, green: 0.91, blue: 0.96)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // TACHIMETRO GRANDE NATIVO CON EFFETTO LIQUID GLASS
                        tachometerSection
                        
                        // CONTROLLO SESSIONE / CRONOMETRO IN CORSO
                        sessionControlCard
                        
                        // ANTEPRIMA WIDGET PER LA HOME
                        widgetPreviewSection
                        
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
                HStack(spacing: 6) {
                    Circle()
                        .fill(locationManager.accuracy > 0 && locationManager.accuracy < 15 ? Color.green : Color.yellow)
                        .frame(width: 8, height: 8)
                    Text(locationManager.accuracy > 0 && locationManager.accuracy < 15 ? "GPS OTTIMALE" : "SEGNALE GPS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.5)
                        .foregroundColor(.cyan.opacity(0.8))
                }
                .padding(.top, 20)
                
                // Velocità in grande con 1 decimale per precisione sportiva
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    let whole = Int(locationManager.currentSpeedKmh)
                    let decimal = Int((locationManager.currentSpeedKmh.truncatingRemainder(dividingBy: 1.0)) * 10)
                    
                    Text("\(whole)")
                        .font(.system(size: 88, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colorScheme == .dark ? [.white, .white.opacity(0.92)] : [Color(red: 0.1, green: 0.12, blue: 0.18), Color(red: 0.15, green: 0.2, blue: 0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .contentTransition(.numericText())
                    
                    Text(".\(abs(decimal))")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan.opacity(0.85))
                        .contentTransition(.numericText())
                    
                    Text("km/h")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(.leading, 4)
                }
                
                // Accelerazione istantanea più piccola sotto con asse G
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("ACCEL:")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.2f %@", motionManager.displayAcceleration, motionManager.selectedUnit.label))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(.orange)
                        .contentTransition(.numericText())
                    
                    // Indicatore G Laterale / Centrifugo
                    if abs(motionManager.lateralG) > 0.05 {
                        Text(String(format: "• Lat: %.2f G", motionManager.lateralG))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.yellow.opacity(0.9))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .padding(.bottom, 22)
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
    private var widgetPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("WIDGET TELEMETRIA (HOME SCREEN)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Spacer()
                Text("Stile Liquid Glass")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)
            
            LiquidGlassCard(cornerRadius: 22) {
                HStack(spacing: 16) {
                    InAppWidgetPreview(
                        speed: locationManager.currentSpeedKmh,
                        accel: motionManager.currentAccelerationG,
                        maxSpeed: lapEngine.maxSpeedKmh,
                        circuitName: lapEngine.activeCircuit?.name
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Widget iOS Disponibile")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : Color(red: 0.1, green: 0.12, blue: 0.18))
                        
                        Text("Tieni premuto sulla Home del tuo iPhone, tocca '+' in alto a sinistra e aggiungi 'SpeedTracker' per vedere velocità e accelerazione in tempo reale!")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(14)
            }
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
