import SwiftUI
import SwiftData

/// Project workspace container — owns the back bar and the
/// Overview/Story/Audio/Publish section strip once, and swaps the
/// section content below them in place. Section-root views are
/// embedded with `chromeHidden` so the chrome never remounts on a
/// section switch; detail screens pushed on top keep their own.
struct ProjectWorkspaceView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    let initialSection: ProjectSection

    @State private var section: ProjectSection
    @State private var project: Project?
    @State private var loadError: String?

    init(projectID: UUID, initialSection: ProjectSection = .overview) {
        self.projectID = projectID
        self.initialSection = initialSection
        _section = State(initialValue: initialSection)
    }

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: project?.title ?? "Project") {
                coordinator.pop()
            }
            if let project {
                ProjectSectionTabs(
                    projectID: project.id,
                    active: section,
                    selection: $section
                )
                Group { sectionContent(project) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn't open project",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task(id: section) {
            // Re-fetch on section switches so content routing
            // (ideas vs. outline, casting vs. studio) tracks flags
            // changed by detail screens (e.g. outline approval).
            project = try? SwiftDataDashboardRepository(context: modelContext)
                .fetchProject(id: projectID)
            if project == nil { loadError = "That project couldn't be found." }
        }
    }

    @ViewBuilder
    private func sectionContent(_ project: Project) -> some View {
        switch section {
        case .overview:
            ProjectOverviewView(projectID: projectID, chromeHidden: true)
        case .story:
            if project.hasOutline {
                OutlineView(projectID: projectID, chromeHidden: true)
            } else {
                IdeasView(projectID: projectID, chromeHidden: true)
            }
        case .audio:
            if project.narratorConfirmed {
                NarrationView(projectID: projectID, chromeHidden: true)
            } else {
                CastingView(projectID: projectID, chromeHidden: true)
            }
        case .publish:
            DocumentsView(projectID: projectID, chromeHidden: true)
        }
    }
}
