import SwiftUI

/// Semantic design tokens extracted from the CoAuthor dashboard design
/// (Designs/Full Content/Dashboard). Extend per-milestone; do not add
/// tokens that no screen uses yet.
enum Theme {

    enum Spacing {
        /// Page horizontal padding.
        static let page: CGFloat = 16
        /// Inner card padding.
        static let card: CGFloat = 14
        /// Vertical gap between cards.
        static let cardGap: CGFloat = 12
        /// Gap inside dense rows.
        static let rowGap: CGFloat = 6
    }

    enum Radius {
        static let card: CGFloat = 14
        static let button: CGFloat = 10
        static let badge: CGFloat = 999
        static let image: CGFloat = 10
    }
}

extension Color {
    /// Screen background, sampled from design (#F5F5F5).
    static let caBackground = Color(red: 0.961, green: 0.961, blue: 0.961)
    /// Card / header / tab bar surfaces (#FFFFFF).
    static let caSurface = Color.white
    /// Primary ink — buttons, titles, active tab (#111111).
    static let caInk = Color(red: 0.067, green: 0.067, blue: 0.067)
    /// Secondary text (subtitles, metadata).
    static let caSecondary = Color(red: 0.42, green: 0.45, blue: 0.50)
    /// Hairline borders on cards and bars (~#E5E7EB).
    static let caHairline = Color(red: 0.898, green: 0.906, blue: 0.922)
    /// Warm badge fill — "Review" (#FBF2DE).
    static let caBadgeWarm = Color(red: 0.984, green: 0.949, blue: 0.871)
    /// Lighter warm badge fill — "Approve" (#F7F5F0).
    static let caBadgeWarmLight = Color(red: 0.969, green: 0.961, blue: 0.941)
    /// Neutral badge fill — "Draft".
    static let caBadgeNeutral = Color(red: 0.937, green: 0.937, blue: 0.941)
    /// Status-bar style pill behind "Saved".
    static let caPill = Color(red: 0.949, green: 0.949, blue: 0.957)
    /// Fallback for missing cover art.
    static let caCoverFallback = Color(red: 0.13, green: 0.16, blue: 0.18)
    /// Form input fill — near-white with a hint of gray.
    static let caField = Color(red: 0.972, green: 0.972, blue: 0.976)
}

extension Font {
    /// Serif display face used for story titles (system serif until the
    /// design's exact face is confirmed — see milestone doc).
    static func caSerif(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}
