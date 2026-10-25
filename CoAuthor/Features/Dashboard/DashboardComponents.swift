import SwiftUI

/// Dashboard subviews, factored so `DashboardView` stays readable.

// MARK: - Continue card

/// Featured project card with cover art, metadata, and the two
/// primary actions from the design.
struct ContinueCard: View {
    let project: Project
    let editedDescription: String
    let onContinue: () -> Void
    let onOpen: () -> Void

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    SectionLabel("Continue")
                    Spacer()
                    Text(project.totalChapters > 0
                         ? "\(project.narratedChapters) of \(project.totalChapters) narrated"
                         : project.stageLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.caPill)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, Theme.Spacing.card)
                .padding(.top, Theme.Spacing.card)
                .padding(.bottom, 10)

                // Cover bleeds to the card edges per the design.
                cover

                VStack(alignment: .leading, spacing: Theme.Spacing.rowGap) {
                    Text("\(project.genre) · \(project.settingDescriptor)")
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    Text("\(project.narratorFormat) · ~\(project.runtimeTargetMinutes) min target · Edited \(editedDescription)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, Theme.Spacing.card)
                .padding(.top, 10)

                HStack(spacing: 10) {
                    Button("Continue narration", action: onContinue)
                        .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))
                    Button("Open story", action: onOpen)
                        .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                }
                .padding(Theme.Spacing.card)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var cover: some View {
        if let name = project.coverImageName {
            Image(name)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 148)
                .clipped()
        } else {
            // Fallback when a project has no cover art yet.
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.caCoverFallback, Color.caInk],
                    startPoint: .top, endPoint: .bottom
                )
                Text(project.title)
                    .font(.caSerif(24))
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 148)
        }
    }
}

// MARK: - Stat tiles

struct StatTile: View {
    let label: String
    let value: String
    let sublabel: String

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text(value)
                    .font(.headline)
                Text(sublabel)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(12)
        }
    }
}

// MARK: - Grouped list card

/// Shared card shell used by "Recent projects" and "Review queue":
/// bold header + trailing summary + divided rows.
struct ListCard<Content: View>: View {
    let title: String
    let trailing: String
    @ViewBuilder var content: Content

    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(trailing)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, Theme.Spacing.card)
                .padding(.vertical, 12)

                content
            }
        }
    }
}

struct ProjectRow: View {
    let project: Project
    let editedDescription: String

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.subheadline.weight(.semibold))
                Text("\(project.genre) · \(project.settingDescriptor)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("\(project.stageLabel) · \(editedDescription)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer(minLength: 8)
            StatusBadge(project.status.badgeLabel, kind: project.status.badgeKind)
        }
        .padding(.horizontal, Theme.Spacing.card)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct ReviewItemRow: View {
    let item: ReviewItem

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer(minLength: 8)
            StatusBadge(item.actionLabel, kind: item.actionLabel == "Approve" ? .warmLight : .warm)
        }
        .padding(.horizontal, Theme.Spacing.card)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

extension ProjectStatus {
    var badgeLabel: String {
        switch self {
        case .draft: "Draft"
        case .review: "Review"
        case .inProgress: "Active"
        case .complete: "Done"
        }
    }

    var badgeKind: StatusBadgeKind {
        switch self {
        case .draft: .neutral
        case .review: .warm
        case .inProgress: .warmLight
        case .complete: .neutral
        }
    }
}
