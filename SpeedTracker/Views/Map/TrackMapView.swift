import SwiftUI
import MapKit

public enum MapViewStyle: String, CaseIterable {
    case standard = "Solo Strade"
    case satellite = "Satellite"
    
    public var mapKitStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(elevation: .realistic)
        case .satellite:
            return .imagery(elevation: .realistic)
        }
    }
}

public struct TrackMapView: View {
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var lapEngine = LapDetectionEngine.shared
    @ObservedObject var storage = DataStorage.shared
    
    @State private var selectedMapStyle: MapViewStyle = .standard
    @State private var showingCircuitEditor: Bool = false
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // MAPPA MAPKIT NATIVA
                Map(position: $position) {
                    UserAnnotation()
                    
                    // Mostra il circuito attivo selezionato (se presente)
                    if let circuit = lapEngine.activeCircuit {
                        Annotation("START", coordinate: circuit.startPoint.clCoordinate) {
                            ZStack {
                                Circle().fill(Color.green).frame(width: 28, height: 28)
                                Image(systemName: "flag.fill").foregroundColor(.white).font(.system(size: 12))
                            }
                        }
                        
                        ForEach(circuit.checkpoints) { cp in
                            Annotation("CP \(cp.order)", coordinate: cp.coordinate.clCoordinate) {
                                Circle().fill(Color.yellow).frame(width: 22, height: 22)
                                    .overlay(Text("\(cp.order)").font(.caption2.bold()).foregroundColor(.black))
                            }
                        }
                        
                        if circuit.roadPathPoints.count >= 2 {
                            MapPolyline(coordinates: circuit.roadPathPoints.map(\.clCoordinate))
                                .stroke(Color.cyan, lineWidth: 5)
                        }
                    }
                }
                .mapStyle(selectedMapStyle.mapKitStyle)
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapPitchToggle()
                }
                
                // FLOATING OVERLAY: TOP BAR & MINI HUD
                VStack {
                    HStack {
                        // MINI HUD TACHIMETRO COMPATTO
                        MiniSpeedHUD()
                        
                        Spacer()
                        
                        // SELETTORE STILE MAPPA (SATELLITE / STRADE)
                        Picker("Stile Mappa", selection: $selectedMapStyle) {
                            ForEach(MapViewStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                        .padding(4)
                        .liquidGlass(cornerRadius: 16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // PULSANTE CREA CIRCUITO FLOATING IN BASSO
                    HStack {
                        Button {
                            showingCircuitEditor = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                                    .font(.headline)
                                Text("Crea Circuito")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.cyan.opacity(0.4), radius: 10, y: 5)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Mappa Live")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingCircuitEditor) {
                CircuitEditorView()
            }
        }
    }
}
