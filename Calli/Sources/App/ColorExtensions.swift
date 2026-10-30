import SwiftUI
import UIKit

extension Color {
    static let appBackground = Color(red: 239.0 / 255.0, green: 239.0 / 255.0, blue: 239.0 / 255.0)
    static let primaryText = Color(white: 0.12)
    static let secondaryText = Color(white: 0.42)
    static let accessibleBlue = Color(red: 0.0, green: 0.35, blue: 0.78)
}

enum WCAGContrastCalculator {
    static func relativeLuminance(red: Double, green: Double, blue: Double) -> Double {
        func linearize(_ channel: Double) -> Double {
            let clamped = min(max(channel, 0.0), 1.0)
            return clamped <= 0.03928 ? (clamped / 12.92) : pow((clamped + 0.055) / 1.055, 2.4)
        }
        let r = linearize(red)
        let g = linearize(green)
        let b = linearize(blue)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    static func contrastRatio(
        foreground: (red: Double, green: Double, blue: Double),
        background: (red: Double, green: Double, blue: Double)
    ) -> Double {
        let lum1 = relativeLuminance(red: foreground.red, green: foreground.green, blue: foreground.blue)
        let lum2 = relativeLuminance(red: background.red, green: background.green, blue: background.blue)
        let lighter = max(lum1, lum2)
        let darker = min(lum1, lum2)
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func contrastRatio(foregroundWhite: Double, backgroundWhite: Double) -> Double {
        contrastRatio(
            foreground: (foregroundWhite, foregroundWhite, foregroundWhite),
            background: (backgroundWhite, backgroundWhite, backgroundWhite)
        )
    }
}
