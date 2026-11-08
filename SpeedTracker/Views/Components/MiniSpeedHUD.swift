import SwiftUI

public struct MiniSpeedHUD: View {
    @ObservedObject var locationManager = LocationManager.shared
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "speedometer")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cyan)
            
            Text(String(format: "%.0f", locationManager.currentSpeedKmh))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .contentTransition(.numericText())
            
            Text("KM/H")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .liquidGlass(cornerRadius: 18)
    }
}
