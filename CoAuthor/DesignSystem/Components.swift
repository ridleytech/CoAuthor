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

// MARK: - Top bars

/// Brand header ("CoAuthor" + Saved pill) used on the dashboard.
struct BrandTopBar: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("CoAuthor")
                    .font(.title3.weight(.bold))
                Spacer()
                SavedPill()
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, 12)
            Divider().overlay(Color.caHairline)
        }
        .background(Color.caSurface)
    }
}

/// Back-navigation header used on pushed screens
/// ("< The Numbers Widow" + Saved pill).
struct BackTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                SavedPill()
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, 12)
            Divider().overlay(Color.caHairline)
        }
        .background(Color.caSurface)
    }
}

// MARK: - Fixed bottom CTA

/// Sticky primary action pinned above the tab bar, matching the
/// design's bottom button treatment.
struct BottomCTA: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.caHairline)
            Button(title, action: action)
                .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))
                .disabled(!enabled)
                .opacity(enabled ? 1 : 0.4)
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, 10)
        }
        .background(Color.caSurface)
    }
}

// MARK: - Form fields

/// Labeled text input matching the design's story-details fields:
/// label above, light rounded input below.
struct CAFormField: View {
    let label: String
    @Binding var text: String
    var placeholder = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.caField)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
    }
}

/// Labeled dropdown field rendered as a `Menu`, matching the
/// design's picker rows ("Genre", "Tone / audience", …).
struct CAPickerField<Option: Hashable>: View {
    let label: String
    let options: [Option]
    @Binding var selection: Option
    var optionLabel: (Option) -> String = { String(describing: $0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(optionLabel(option)) { selection = option }
                }
            } label: {
                HStack {
                    Text(optionLabel(selection))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.caField)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Radio option row

/// Selectable option card from the create-project workflow picker:
/// filled dark when selected, bordered white otherwise.
struct RadioOptionCard: View {
    let title: String
    let detail: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.body)
                    .foregroundStyle(selected ? .white : Color.caSecondary)
                    .padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(detail)
                        .font(.footnote)
                        .opacity(selected ? 0.85 : 1)
                }
                .foregroundStyle(selected ? .white : Color.caInk)
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.caInk : Color.caSurface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(selected ? Color.clear : Color.caHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
