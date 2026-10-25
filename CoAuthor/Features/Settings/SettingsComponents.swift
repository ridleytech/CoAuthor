import SwiftUI

/// Back header used on Settings sub-screens: "‹ Settings" on the
/// left, the "CoAuthor" wordmark on the right — matching the
/// Account/Credits designs.
struct SettingsBackBar: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("Settings")
                            .font(.body)
                    }
                    .foregroundStyle(Color.caInk)
                    .frame(height: 24)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back to settings")
                Spacer()
                Text("CoAuthor")
                    .font(.headline)
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, 12)
            Divider().overlay(Color.caHairline)
        }
        .background(Color.caSurface)
    }
}

/// Chevron row used inside settings cards.
struct SettingsNavRow: View {
    let title: String
    var detail: String? = nil
    var isLast = false
    var destructive = false
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(destructive
                                             ? Color.caDestructive
                                             : Color.caInk)
                        if let detail {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(Color.caSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if !isLast {
                Divider().overlay(Color.caHairline)
            }
        }
    }
}
