import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Palette {
    // Login, sign up, home and cafes screens.
    static let coffeeBackground = Color(hex: 0xF5EDE3)
    static let coffeePrimary = Color(hex: 0x6F4E37)
    static let coffeeSecondary = Color(hex: 0xB08968)
    static let accent = Color(hex: 0xF26B3A)
    static let serverError = Color(hex: 0xB00020)
    static let starYellow = Color(hex: 0xF5B301)
    static let cafeThumbBackground = Color(hex: 0xEFE1D1)
    static let sunYellow = Color(hex: 0xFFC107)

    // Menu, order and profile screens.
    static let orderBackground = Color(hex: 0xF8F4EF)
    static let coffeeBrown = Color(hex: 0x6F4E37)
    static let textDark = Color(hex: 0x2B211B)
    static let textGrey = Color(hex: 0x6B625C)
    static let divider = Color(hex: 0xE6DFD8)
    static let statusGreenBackground = Color(hex: 0xE3F1E6)
    static let statusGreen = Color(hex: 0x2E6B3F)
    static let soldOutBackground = Color(hex: 0xEFE6DC)
    static let inputBackground = Color(hex: 0xF1E8DE)
    static let cardBorder = Color(hex: 0xE6DFD8)
    static let heroLight = Color(hex: 0xC8A27C)
    static let heroDark = Color(hex: 0x4A3426)
    static let errorRed = Color(hex: 0xB3261E)

    // Order status stepper.
    static let stepCurrent = Color(hex: 0xB8761B)
    static let stepCurrentHalo = Color(hex: 0xF1D9B5)
    static let stepPending = Color(hex: 0xBDB5AE)
    static let headingBrown = Color(hex: 0x3E2C23)
}
