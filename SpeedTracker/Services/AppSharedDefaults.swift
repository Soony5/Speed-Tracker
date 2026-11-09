import Foundation

public final class AppSharedDefaults {
    public static let shared = AppSharedDefaults()
    
    // Suite per sincronizzazione con App Group (o standard UserDefaults come fallback trasparente)
    public let userDefaults: UserDefaults
    
    private init() {
        if let groupDefaults = UserDefaults(suiteName: "group.com.pietroferrari.speedtracker") {
            self.userDefaults = groupDefaults
        } else {
            self.userDefaults = UserDefaults.standard
        }
    }
    
    public var lastSpeedKmh: Double {
        get { userDefaults.double(forKey: "widget_last_speed") }
        set { userDefaults.set(newValue, forKey: "widget_last_speed") }
    }
    
    public var maxSpeedKmh: Double {
        get { userDefaults.double(forKey: "widget_max_speed") }
        set { userDefaults.set(newValue, forKey: "widget_max_speed") }
    }
    
    public var lastAccelG: Double {
        get { userDefaults.double(forKey: "widget_last_accel") }
        set { userDefaults.set(newValue, forKey: "widget_last_accel") }
    }
    
    public var accelUnit: String {
        get { userDefaults.string(forKey: "speed_tracker_accel_unit") ?? "G" }
        set { userDefaults.set(newValue, forKey: "speed_tracker_accel_unit") }
    }
    
    public var activeCircuitName: String? {
        get { userDefaults.string(forKey: "widget_circuit_name") }
        set { userDefaults.set(newValue, forKey: "widget_circuit_name") }
    }
    
    public var lastUpdated: Date {
        get { Date(timeIntervalSince1970: userDefaults.double(forKey: "widget_last_updated")) }
        set { userDefaults.set(newValue.timeIntervalSince1970, forKey: "widget_last_updated") }
    }
}
