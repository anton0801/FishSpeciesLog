import SwiftUI

struct Theme {
    // Colors
    static let primaryBlue = Color(hex: "1E88E5")
    static let secondaryGreen = Color(hex: "26A69A")
    static let accentCoral = Color(hex: "FF6F61")
    static let backgroundAqua = Color(hex: "F0F8FF")
    static let cardBackground = Color(hex: "FAFCFF")
    static let textPrimary = Color(hex: "2C3E50")
    static let textSecondary = Color(hex: "7F8C8D")
    
    // Gradients
    static let oceanGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue, secondaryGreen]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let waveGradient = LinearGradient(
        gradient: Gradient(colors: [primaryBlue.opacity(0.3), secondaryGreen.opacity(0.2)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [cardBackground, Color.white]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let cardShadow = Shadow(color: primaryBlue.opacity(0.15), radius: 10, x: 0, y: 5)
    
    // Fonts
    static func avenirBold(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Bold", size: size)
    }
    
    static func avenirMedium(_ size: CGFloat) -> Font {
        .custom("AvenirNext-Medium", size: size)
    }
    
    static func sfProRounded(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
