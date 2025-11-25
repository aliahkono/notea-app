import SwiftUI

extension Color {
    /// Create a Color from a hex string like "#RRGGBB" or "RRGGBB" or "AARRGGBB".
    init(hex: String) {
        let r, g, b, a: Double
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        // Support short form RGB (e.g. FFF) by expanding
        if hexString.count == 3 {
            let chars = Array(hexString)
            hexString = "\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
        }

        var hexNumber: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&hexNumber)

        switch hexString.count {
        case 6:
            r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
            g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
            b = Double(hexNumber & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            a = Double((hexNumber & 0xFF000000) >> 24) / 255.0
            r = Double((hexNumber & 0x00FF0000) >> 16) / 255.0
            g = Double((hexNumber & 0x0000FF00) >> 8) / 255.0
            b = Double(hexNumber & 0x000000FF) / 255.0
        default:
            // fallback to gray
            r = 0.5; g = 0.5; b = 0.5; a = 1.0
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Convenience to match your existing usage Color(hex: "#RRGGBB")
    static func hex(_ hex: String) -> Color {
        return Color(hex: hex)
    }
}
