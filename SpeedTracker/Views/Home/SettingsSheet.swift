import SwiftUI

public struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var motionManager = MotionManager.shared
    
    @AppStorage("speed_tracker_gps_radius") private var triggerRadius: Double = 25.0
    @AppStorage("speed_tracker_haptic_feedback") private var hapticFeedbackEnabled: Bool = true
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.07, green: 0.08, blue: 0.12).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Sezione Sensori & Unità
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TELEMETRIA & SENSORI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 4)
                            
                            LiquidGlassCard(cornerRadius: 18) {
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Unità Accelerazione")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("Scegli tra forza G gravitazionale e m/s²")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        
                                        Picker("Unità", selection: $motionManager.selectedUnit) {
                                            ForEach(AccelerationUnit.allCases, id: \.self) { unit in
                                                Text(unit.label).tag(unit)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                        .frame(width: 140)
                                    }
                                    
                                    Divider().background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Feedback Aptico")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("Vibrazione al passaggio dai checkpoint")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Toggle("", isOn: $hapticFeedbackEnabled)
                                            .labelsHidden()
                                            .tint(.cyan)
                                    }
                                }
                                .padding(16)
                            }
                        }
                        
                        // Sezione Geofence & Circuiti
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SENSIBILITÀ CIRCUITI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 4)
                            
                            LiquidGlassCard(cornerRadius: 18) {
                                VStack(alignment: .leading, spacing: 14) {
                                    HStack {
                                        Text("Raggio Trigger Checkpoint")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(Int(triggerRadius)) metri")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.cyan)
                                    }
                                    
                                    Slider(value: $triggerRadius, in: 10...50, step: 5)
                                        .tint(.cyan)
                                    
                                    Text("Raggio di tolleranza GPS per rilevare automaticamente la linea di partenza, i checkpoint e il traguardo.")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                            }
                        }
                        
                        // Informazioni App & AltStore
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INFO & BUILD")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 4)
                            
                            LiquidGlassCard(cornerRadius: 18) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Versione App")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("1.0.0 (AltStore Edition)")
                                            .foregroundColor(.gray)
                                    }
                                    Divider().background(Color.white.opacity(0.1))
                                    HStack {
                                        Text("Engine GPS / IMU")
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("CoreLocation + CoreMotion 30Hz")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

