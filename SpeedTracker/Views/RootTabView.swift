import SwiftUI

public struct RootTabView: View {
    @State private var selectedTab: Int = 0
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var motionManager = MotionManager.shared
    @ObservedObject var lapEngine = LapDetectionEngine.shared
    @ObservedObject var storage = DataStorage.shared
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "speedometer")
                }
                .tag(0)
            
            TrackMapView()
                .tabItem {
                    Label("Mappa", systemImage: "map.fill")
                }
                .tag(1)
            
            ArchiveMainView()
                .tabItem {
                    Label("Archivio", systemImage: "archivebox.fill")
                }
                .tag(2)
        }
        .tint(.cyan)
        .onAppear {
            setupAppearance()
            locationManager.requestAuthorization()
            locationManager.startUpdating()
            
            // Collega gli aggiornamenti di posizione e accelerazione al Lap Engine
            locationManager.onLocationUpdate = { location in
                lapEngine.processLocationUpdate(location, currentAccelG: motionManager.currentAccelerationG)
            }
            
            // Salvataggio automatico sessione completata
            lapEngine.onSessionCompleted = { session in
                storage.saveRunSession(session)
            }
        }
    }
    
    private func setupAppearance() {
        // Look & Feel Liquid Glass scuro per TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        }
    }
}

