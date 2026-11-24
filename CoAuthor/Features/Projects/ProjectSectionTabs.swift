import SwiftUI

/// Sections of a project's workspace, shown as the underlined tab
/// strip below the back header on project screens.
enum ProjectSection: CaseIterable, Hashable {
    case overview, story, audio, publish

    var title: String {
        switch self {
        case .overview: "Overview"
        case .story: "Story"
        case .audio: "Audio"
        case .publish: "Publish"
        }
    }
}

/// Underlined tab strip shared by project screens. The active section
/// renders in ink; tapping another section switches to it (the stack
/// resets to that section — tab semantics, not pushed screens).
struct ProjectSectionTabs: View {
    @Environment(AppCoordinator.self) private var coordinator
    let projectID: UUID
    let active: ProjectSection
    /// Where the Story tab leads — ideas during setup, the outline
    /// once one exists.
    var storyDestination: AppRoute? = nil
    /// Where the Audio tab leads — casting until a narrator is
    /// confirmed, the narration studio after.
    var audioDestination: AppRoute? = nil
    /// When set (inside `ProjectWorkspaceView`), taps switch the
    /// section in place — the bar and strip stay mounted and only
    /// the content below changes. When nil (detail screens), taps
    /// reset the stack to the workspace on that section.
    var selection: Binding<ProjectSection>? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(Array(ProjectSection.allCases.enumerated()), id: \.offset) { pair in
                    let section = pair.element
                    if section == active {
                        tabItem(section.title, active: true)
                    } else {
                        Button { select(section) } label: {
                            tabItem(section.title, active: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.top, 8)
            Divider().overlay(Color.caHairline)
        }
        .background(Color.caSurface)
    }

    private func select(_ section: ProjectSection) {
        if let selection {
            selection.wrappedValue = section
        } else {
            coordinator.switchSection(
                .projectWorkspace(projectID: projectID, section: section))
        }
    }

    private func tabItem(_ title: String, active: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active ? Color.caInk : Color.caSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(active ? Color.caInk : Color.clear)
                .frame(height: 2)
                .accessibilityHidden(true)
        }
        .accessibilityAddTraits(active ? .isSelected : [])
    }
}

/// Light gray info pill ("3 of 10 narrated").
struct InfoPill: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.caPill)
            .clipShape(Capsule())
    }
}
