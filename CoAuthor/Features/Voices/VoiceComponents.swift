import SwiftUI

/// Mock account-capacity card shared across the voices screens —
/// "ElevenLabs · Custom voices / 8 of 10 slots used" with a progress
/// bar. Slots are not credits; the count includes voices created
/// outside CoAuthor.
struct VoiceCapacityCard: View {
    let capacity: VoiceCapacity
    var footnote = "Illustrative account capacity · Includes outside CoAuthor"

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(capacity.provider) · \(capacity.groupLabel)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("Refresh")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                }
                Text(capacity.headline)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.caHairline)
                        Capsule()
                            .fill(Color.caInk)
                            .frame(width: geometry.size.width * capacity.fraction)
                    }
                }
                .frame(height: 6)
                Text(capacity.detailLine)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text(capacity.refreshedLine)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}

/// Small uppercase-ish tag chip ("Narrator", "Warm", "Mature").
struct VoiceTagPill: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color.caSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.caPill)
            .clipShape(Capsule())
    }
}

/// Audition player strip — play/pause toggle, title, position, speed.
/// Cosmetic playback; real audio preview is backend-driven.
struct VoiceAuditionStrip: View {
    let title: String
    let position: String
    let duration: String
    let isPlaying: Bool
    let onToggle: () -> Void

    var body: some View {
        CardContainer {
            HStack(spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    ProgressView(value: 0.35)
                        .tint(Color.caInk)
                }
                Text("\(position)\n\(duration)")
                    .font(.caption)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(Color.caSecondary)
                Text("1×")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}

/// Search field matching the voices list ("Search voices").
struct VoiceSearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            TextField("Search voices", text: $text)
                .textFieldStyle(.plain)
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
}

/// Filter pill used on the voices list — tappable menu or toggle,
/// filled ink when active.
struct VoiceFilterPill<Content: View>: View {
    let content: Content

    init(@ViewBuilder _ content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.caSurface)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(Color.caHairline, lineWidth: 1)
            )
    }
}
