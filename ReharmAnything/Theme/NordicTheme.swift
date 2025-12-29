import SwiftUI

// Nordic-inspired color palette with clean, minimal aesthetic
struct NordicTheme {
    
    // MARK: - Base Colors
    struct Colors {
        // Primary accent - muted blue-gray
        static let accent = Color("AccentColor")
        
        // Light mode colors
        static let lightBackground = Color(red: 0.98, green: 0.98, blue: 0.97)      // Warm off-white
        static let lightSurface = Color.white
        static let lightSurfaceSecondary = Color(red: 0.96, green: 0.96, blue: 0.95)
        static let lightText = Color(red: 0.15, green: 0.15, blue: 0.18)
        static let lightTextSecondary = Color(red: 0.45, green: 0.45, blue: 0.50)
        static let lightBorder = Color(red: 0.88, green: 0.88, blue: 0.86)
        
        // Dark mode colors
        static let darkBackground = Color(red: 0.08, green: 0.09, blue: 0.10)       // Deep charcoal
        static let darkSurface = Color(red: 0.12, green: 0.13, blue: 0.15)
        static let darkSurfaceSecondary = Color(red: 0.16, green: 0.17, blue: 0.19)
        static let darkText = Color(red: 0.95, green: 0.95, blue: 0.93)
        static let darkTextSecondary = Color(red: 0.60, green: 0.60, blue: 0.58)
        static let darkBorder = Color(red: 0.22, green: 0.23, blue: 0.25)
        
        // Accent colors - muted and sophisticated
        static let primary = Color(red: 0.35, green: 0.45, blue: 0.55)              // Slate blue
        static let primaryLight = Color(red: 0.50, green: 0.60, blue: 0.70)
        static let secondary = Color(red: 0.65, green: 0.55, blue: 0.50)            // Warm taupe
        static let tertiary = Color(red: 0.40, green: 0.50, blue: 0.45)             // Sage green
        
        // Semantic colors
        static let success = Color(red: 0.45, green: 0.60, blue: 0.50)              // Muted green
        static let warning = Color(red: 0.75, green: 0.60, blue: 0.40)              // Warm amber
        static let error = Color(red: 0.75, green: 0.40, blue: 0.40)                // Muted red
        static let highlight = Color(red: 0.55, green: 0.50, blue: 0.65)            // Soft lavender
    }
    
    // MARK: - Dynamic Colors (adapt to color scheme)
    struct Dynamic {
        @Environment(\.colorScheme) static var colorScheme
        
        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkBackground : Colors.lightBackground
        }
        
        static func surface(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkSurface : Colors.lightSurface
        }
        
        static func surfaceSecondary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkSurfaceSecondary : Colors.lightSurfaceSecondary
        }
        
        static func text(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkText : Colors.lightText
        }
        
        static func textSecondary(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkTextSecondary : Colors.lightTextSecondary
        }
        
        static func border(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Colors.darkBorder : Colors.lightBorder
        }
        
        static func shadowColor(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06)
        }
    }
}

// MARK: - View Modifiers

struct NordicCardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(NordicTheme.Dynamic.surface(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(NordicTheme.Dynamic.border(colorScheme), lineWidth: 0.5)
            )
            .shadow(
                color: NordicTheme.Dynamic.shadowColor(colorScheme),
                radius: 8,
                y: 2
            )
    }
}

struct NordicButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected 
                        ? NordicTheme.Colors.primary.opacity(colorScheme == .dark ? 0.3 : 0.12)
                        : NordicTheme.Dynamic.surfaceSecondary(colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected 
                        ? NordicTheme.Colors.primary.opacity(0.5)
                        : Color.clear, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func nordicCard() -> some View {
        modifier(NordicCardStyle())
    }
    
    func nordicBackground(_ colorScheme: ColorScheme) -> some View {
        self.background(NordicTheme.Dynamic.background(colorScheme))
    }
}
