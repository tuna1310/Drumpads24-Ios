import SwiftUI

public enum AppTheme {
    // Deep Navy Dark Backgrounds
    public static let navyBackground = Color(hex: "#0C0E1B")
    public static let navySurface = Color(hex: "#14172B")
    public static let navyCard = Color(hex: "#1B2039")
    public static let navyCardElevated = Color(hex: "#232948")
    public static let navyBorder = Color(hex: "#282F52")

    // Vivid Accents
    public static let accentYellow = Color(hex: "#FFD233")
    public static let accentYellowMuted = Color(hex: "#C7A528")
    public static let accentPurple = Color(hex: "#7B2CBF")
    public static let accentPink = Color(hex: "#FF2A85")
    public static let accentCyan = Color(hex: "#00E5FF")
    public static let dangerRed = Color(hex: "#EF4444")
    public static let proBadge = Color(hex: "#8B5CF6")

    // Pad Neon Colors - Scene A
    public static let padLimeGreen = Color(hex: "#38E54D")
    public static let padVividOrange = Color(hex: "#FF7A00")
    public static let padNeonMagenta = Color(hex: "#E040FB")
    public static let padElectricSkyBlue = Color(hex: "#00B0FF")

    // Pad Neon Colors - Scene B
    public static let padHotPink = Color(hex: "#FF2E93")
    public static let padElectricViolet = Color(hex: "#9D00FF")
    public static let padNeonAmber = Color(hex: "#FFD600")
    public static let padNeonAqua = Color(hex: "#00F5D4")

    // Text Hierarchy
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "#8E99B7")
    public static let textMuted = Color(hex: "#5A6482")

    // Button & Brand Gradients
    public static let brandPinkCyan = LinearGradient(
        colors: [Color(hex: "#FF2A85"), Color(hex: "#00DFD8")],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let studioCardGradient = LinearGradient(
        colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let vipBannerGradient = LinearGradient(
        colors: [Color(hex: "#FF007F"), Color(hex: "#7928CA"), Color(hex: "#00DFD8")],
        startPoint: .leading,
        endPoint: .trailing
    )

    public static let padPlayerBackground = LinearGradient(
        colors: [
            Color(hex: "#260D45"),
            Color(hex: "#140D2A"),
            Color(hex: "#0C0E1B"),
            Color(hex: "#070810")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 128, 128, 128)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

