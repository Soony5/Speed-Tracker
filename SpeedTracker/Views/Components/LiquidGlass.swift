import SwiftUI

public enum AppThemeMode: String, CaseIterable, Codable {
    case system = "Sistema"
    case dark = "Scuro"
    case light = "Chiaro"
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

// Componente Liquid Glass con riflessi dinamici adattati a Light / Dark mode
public struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    private let content: Content
    private let cornerRadius: CGFloat
    private let strokeColor: Color?
    
    public init(
        cornerRadius: CGFloat = 24,
        strokeColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.strokeColor = strokeColor
        self.content = content()
    }
    
    public var body: some View {
        let isDark = colorScheme == .dark
        let defaultBorderColor = isDark ? Color.white.opacity(0.22) : Color.black.opacity(0.12)
        let activeBorder = strokeColor ?? defaultBorderColor
        let shadowColor = isDark ? Color.black.opacity(0.35) : Color.black.opacity(0.08)
        
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        activeBorder,
                                        activeBorder.opacity(0.05),
                                        activeBorder.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: shadowColor, radius: 18, x: 0, y: 8)
            )
    }
}

public struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var cornerRadius: CGFloat = 20
    
    public func body(content: Content) -> some View {
        let isDark = colorScheme == .dark
        let borderTop = isDark ? Color.white.opacity(0.35) : Color.black.opacity(0.18)
        let borderBottom = isDark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
        let shadowColor = isDark ? Color.black.opacity(0.30) : Color.black.opacity(0.06)
        
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [borderTop, borderBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: shadowColor, radius: 12, x: 0, y: 5)
    }
}

public extension View {
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}
