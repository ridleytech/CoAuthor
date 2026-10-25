import SwiftUI

/// Sections of a project's workspace, shown as the underlined tab
/// strip below the back header on project screens.
enum ProjectSection: CaseIterable {
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
/// renders in ink; tapping another section pushes its route (or a
/// labeled placeholder while its milestone is pending).
struct ProjectSectionTabs: View {
    @Environment(AppCoordinator.self) private var coordinator
    let projectID: UUID
    let active: ProjectSection

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(Array(ProjectSection.allCases.enumerated()), id: \.offset) { pair in
                    let section = pair.element
                    if section == active {
                        tabItem(section.title, active: true)
                    } else {
                        Button { coordinator.push(route(for: section)) } label: {
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

    private func route(for section: ProjectSection) -> AppRoute {
        switch section {
        case .overview: .projectDetail(projectID)
        case .story: .ideaGeneration(projectID: projectID)
        case .audio: .placeholder(title: "Audio review", milestone: "M8")
        case .publish: .placeholder(title: "Publishing kit", milestone: "M10")
        }
    }

    private func tabItem(_ title: String, active: Bool) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(active ? .semibold : .regular))
                .foregroundStyle(active ? Color.caInk : Color.caSecondary)
            Rectangle()
                .fill(active ? Color.caInk : Color.clear)
                .frame(height: 2)
        }
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
