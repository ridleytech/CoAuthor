import SwiftUI

// MARK: - Card container

/// White rounded card with a hairline border — the primary surface
/// used throughout the dashboard design.
struct CardContainer<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.caSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Color.caHairline, lineWidth: 1)
            )
    }
}

// MARK: - Section label

/// Small-caps gray label used at the top of cards ("CONTINUE",
/// "RECENT PROJECTS" style headers).
struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caSecondary)
            .tracking(0.4)
    }
}

// MARK: - Status badge

enum StatusBadgeKind {
    /// Cream badge, e.g. "Review".
    case warm
    /// Pale warm badge, e.g. "Approve".
    case warmLight
    /// Gray badge, e.g. "Draft".
    case neutral

    var fill: Color {
        switch self {
        case .warm: .caBadgeWarm
        case .warmLight: .caBadgeWarmLight
        case .neutral: .caBadgeNeutral
        }
    }
}

struct StatusBadge: View {
    let text: String
    let kind: StatusBadgeKind

    init(_ text: String, kind: StatusBadgeKind = .warm) {
        self.text = text
        self.kind = kind
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(kind.fill)
            .clipShape(Capsule())
    }
}

// MARK: - Saved pill

/// Read-only sync indicator shown in the header ("✓ Saved").
struct SavedPill: View {
    var body: some View {
        Label("Saved", systemImage: "checkmark")
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.caPill)
            .clipShape(Capsule())
            .accessibilityLabel("All changes saved")
    }
}

// MARK: - Button styles

/// Filled black button — primary CTA ("New project", "Continue narration").
struct CAPrimaryButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.caInk)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

/// White bordered button — secondary action ("Open story").
struct CASecondaryButtonStyle: ButtonStyle {
    var fullWidth = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(Color.caInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Color.caSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(Color.caHairline, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
