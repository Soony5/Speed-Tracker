import SwiftUI

@main
struct SpeedTrackerApp: App {
    @AppStorage("speed_tracker_theme_mode") private var themeMode: AppThemeMode = .system
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(themeMode.colorScheme)
        }
    }
}
