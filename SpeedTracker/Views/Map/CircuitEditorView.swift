import SwiftUI
import MapKit

public struct CircuitEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var storage = DataStorage.shared
    @ObservedObject var locationManager = LocationManager.shared
    
    @State private var circuitName: String = ""
    @State private var circuitNotes: String = ""
    @State private var circuitType: CircuitType = .loop
    
    // Punti del circuito in costruzione
    @State private var startPoint: CoordinatePoint?
    @State private var finishPoint: CoordinatePoint?
    @State private var checkpoints: [Checkpoint] = []
    
    // Tracciato calcolato strada
    @State private var calculatedRoadPoints: [CoordinatePoint] = []
    @State private var pendingSegmentPoints: [CoordinatePoint] = [] // Anteprima del segmento live
    @State private var totalDistanceMeters: Double = 0.0
    @State private var estimatedTimeSeconds: Double = 0.0
    
    @State private var isCalculatingRoute: Bool = false
    @State private var currentCenterCoord: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900)
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // MAPPA INTERATTIVA
                MapReader { proxy in
                    Map {
                        // Partenza
                        if let start = startPoint {
                            Annotation("START", coordinate: start.clCoordinate) {
                                ZStack {
                                    Circle().fill(Color.green).frame(width: 32, height: 32)
                                    Image(systemName: "flag.fill").foregroundColor(.white).font(.caption.bold())
                                }
                            }
                        }
                        
                        // Checkpoints
                        ForEach(checkpoints) { cp in
                            Annotation("CP \(cp.order): \(cp.name)", coordinate: cp.coordinate.clCoordinate) {
                                ZStack {
                                    Circle().fill(Color.yellow).frame(width: 28, height: 28)
                                    Text("\(cp.order)")
                                        .font(.caption.bold())
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        
                        // Arrivo (se circuito aperto)
                        if let finish = finishPoint, circuitType == .pointToPoint {
                            Annotation("FINISH", coordinate: finish.clCoordinate) {
                                ZStack {
                                    Circle().fill(Color.red).frame(width: 32, height: 32)
                                    Image(systemName: "flag.checkered").foregroundColor(.white).font(.caption.bold())
                                }
                            }
                        }
                        
                        // Polyline definitiva calcolata
                        if calculatedRoadPoints.count >= 2 {
                            MapPolyline(coordinates: calculatedRoadPoints.map(\.clCoordinate))
                                .stroke(Color.cyan, lineWidth: 5)
                        }
                        
                        // Polyline anteprima del segmento stradale verso il centro / cursore
                        if pendingSegmentPoints.count >= 2 {
                            MapPolyline(coordinates: pendingSegmentPoints.map(\.clCoordinate))
                                .stroke(Color.orange.opacity(0.8), style: StrokeStyle(lineWidth: 4, dash: [6, 4]))
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .onTapGesture { screenPosition in
                        if let coord = proxy.coordinate(from: screenPosition) {
                            handleMapTap(coord)
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                // MIRINO CENTRALE PER GUIDARE IL POSIZIONAMENTO
                VStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(10)
                        .background(Circle().fill(.ultraThinMaterial))
                        .allowsHitTesting(false)
                    Spacer()
                }
                
                // TOP BAR DI STATO & TIPO CIRCUITO
                VStack {
                    LiquidGlassCard(cornerRadius: 18) {
                        VStack(spacing: 10) {
                            Picker("Tipo Circuito", selection: $circuitType) {
                                ForEach(CircuitType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Distanza: \(String(format: "%.2f km", totalDistanceMeters / 1000.0))")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    Text("Tempo stimato: \(formatTime(estimatedTimeSeconds))")
                                        .font(.caption2)
                                        .foregroundColor(.cyan)
                                }
                                Spacer()
                                
                                if isCalculatingRoute {
                                    ProgressView().tint(.cyan)
                                } else {
                                    Text(instructionText)
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(14)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // CONTROLLI IN BASSO
                    bottomControlsCard
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("Crea Circuito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") { saveCircuit() }
                        .foregroundColor(.cyan)
                        .fontWeight(.bold)
                        .disabled(startPoint == nil || (circuitType == .pointToPoint && finishPoint == nil))
                }
            }
        }
    }
    
    private var instructionText: String {
        if startPoint == nil {
            return "Tocca la mappa per impostare lo START"
        } else if finishPoint == nil {
            return "Aggiungi Checkpoint o tocca 'Imposta Fine'"
        } else {
            return "Circuito completato! Clicca Salva"
        }
    }
    
    // MARK: - Barra Controlli Inferiore
    private var bottomControlsCard: some View {
        LiquidGlassCard(cornerRadius: 22) {
            VStack(spacing: 12) {
                // Dettagli nome
                TextField("Nome circuito (es. Passo dello Stelvio)", text: $circuitName)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                HStack(spacing: 10) {
                    // Tasto aggiungi Checkpoint
                    Button {
                        if let lastPoint = lastAddedPoint {
                            addCheckpoint(at: lastPoint.clCoordinate)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "flag.badge.ellipsis")
                            Text("Aggiungi Checkpoint (\(checkpoints.count))")
                        }
                        .font(.footnote.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(startPoint == nil ? Color.gray.opacity(0.3) : Color.cyan.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(startPoint == nil || finishPoint != nil)
                    
                    // Tasto Chiudi / Fine
                    Button {
                        finalizeTrack()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text(circuitType == .loop ? "Chiudi Anello" : "Imposta Fine")
                        }
                        .font(.footnote.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(startPoint == nil ? Color.gray.opacity(0.3) : Color.green.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(startPoint == nil || finishPoint != nil)
                }
            }
            .padding(14)
        }
    }
    
    private var lastAddedPoint: CoordinatePoint? {
        if let lastCp = checkpoints.last {
            return lastCp.coordinate
        }
        return startPoint
    }
    
    // MARK: - Gestione Tap Mappa & Routing
    private func handleMapTap(_ coord: CLLocationCoordinate2D) {
        if startPoint == nil {
            startPoint = CoordinatePoint(clCoordinate: coord)
            calculatedRoadPoints = [CoordinatePoint(clCoordinate: coord)]
        } else if finishPoint == nil {
            // Calcola anteprima stradale live dal punto precedente al punto toccato
            if let prev = lastAddedPoint {
                isCalculatingRoute = true
                Task {
                    if let result = await RoadRoutingService.shared.calculateRoadRoute(from: prev.clCoordinate, to: coord) {
                        await MainActor.run {
                            self.pendingSegmentPoints = result.coordinates
                            self.isCalculatingRoute = false
                        }
                    }
                }
            }
        }
    }
    
    private func addCheckpoint(at coord: CLLocationCoordinate2D) {
        guard finishPoint == nil else { return }
        
        // Se c'era un'anteprima stradale in sospeso, confermala
        if !pendingSegmentPoints.isEmpty {
            calculatedRoadPoints.append(contentsOf: pendingSegmentPoints)
            pendingSegmentPoints.removeAll()
        }
        
        let newIndex = checkpoints.count + 1
        let cp = Checkpoint(
            name: "Settore \(newIndex)",
            order: newIndex,
            coordinate: CoordinatePoint(clCoordinate: coord),
            triggerRadiusMeters: 25.0
        )
        checkpoints.append(cp)
        updateTotalDistanceAndEstimate()
    }
    
    private func finalizeTrack() {
        guard let start = startPoint else { return }
        
        if circuitType == .loop {
            // Chiude il cerchio tornando alla partenza con routing stradale
            if let last = lastAddedPoint {
                isCalculatingRoute = true
                Task {
                    if let result = await RoadRoutingService.shared.calculateRoadRoute(from: last.clCoordinate, to: start.clCoordinate) {
                        await MainActor.run {
                            self.calculatedRoadPoints.append(contentsOf: result.coordinates)
                            self.finishPoint = start
                            self.updateTotalDistanceAndEstimate()
                            self.isCalculatingRoute = false
                        }
                    }
                }
            }
        } else {
            // Circuito aperto
            if let last = lastAddedPoint {
                self.finishPoint = last
                updateTotalDistanceAndEstimate()
            }
        }
    }
    
    private func updateTotalDistanceAndEstimate() {
        var totalDist: Double = 0.0
        guard calculatedRoadPoints.count >= 2 else { return }
        for i in 0..<(calculatedRoadPoints.count - 1) {
            totalDist += calculatedRoadPoints[i].distance(to: calculatedRoadPoints[i + 1])
        }
        totalDistanceMeters = totalDist
        // Stima tempo a ~80 km/h (22.2 m/s)
        estimatedTimeSeconds = totalDist / 22.2
    }
    
    private func saveCircuit() {
        guard let start = startPoint else { return }
        let finish = finishPoint ?? start
        let name = circuitName.trimmingCharacters(in: .whitespaces).isEmpty ? "Nuovo Circuito" : circuitName
        
        let circuit = Circuit(
            name: name,
            notes: circuitNotes,
            circuitType: circuitType,
            startPoint: start,
            finishPoint: finish,
            checkpoints: checkpoints,
            roadPathPoints: calculatedRoadPoints,
            distanceMeters: totalDistanceMeters,
            estimatedTimeSeconds: estimatedTimeSeconds
        )
        
        storage.saveCircuit(circuit)
        dismiss()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d min", mins, secs)
    }
}

