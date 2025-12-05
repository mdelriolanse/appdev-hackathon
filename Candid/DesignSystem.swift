import SwiftUI

struct CandidColors {
    static let background = Color(hex: "E8F5E9") // Light match green
    static let cardBackground = Color(hex: "F1FAF1") // Pale green/white for cards
    static let text = Color(hex: "1B5E20") // Dark green
    static let secondaryText = Color(hex: "9E9E9E") // Gray for secondary text
    static let borderLight = Color(hex: "E0E0E0") // Light gray border
    static let borderDark = Color(hex: "9E9E9E") // Dark gray border
    static let buttonBackground = Color(hex: "1B5E20") // Dark green fill
    
    // Legacy mapping for existing code compatibility (remapping to new scheme)
    static let secondaryBackground = cardBackground // Used for cards
    static let tertiaryBackground = Color(hex: "FFFFFF").opacity(0.5) // Subtle highlight
}

struct CandidTypography {
    static let largeTitleSize: CGFloat = 28
    static let largeTitleWeight: Font.Weight = .bold
    
    static let bodySize: CGFloat = 16
    static let bodyWeight: Font.Weight = .regular
    
    static let captionSize: CGFloat = 14
    static let captionWeight: Font.Weight = .medium
}

struct CandidLayout {
    static let horizontalPadding: CGFloat = 16
    static let verticalSpacing: CGFloat = 12
    static let cornerRadius: CGFloat = 12
    static let borderWidth: CGFloat = 1
}

struct CandidShadows {
    static let card = CandidShadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
}

struct CandidShadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CandidColors.cardBackground)
            .cornerRadius(CandidLayout.cornerRadius)
            .shadow(color: CandidShadows.card.color, radius: CandidShadows.card.radius, x: CandidShadows.card.x, y: CandidShadows.card.y)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
