import SwiftUI
import SwiftData

/// App shell: per-tab navigation stacks over a custom bottom bar
/// matching the design (icons + labels, active tab in ink).
struct RootView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext
    @State private var dashboardViewModel: DashboardViewModel?

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch coordinator.selectedTab {
                case .projects:
                    NavigationStack(path: coordinator.path(for: .projects)) {
                        dashboardRoot
                            .navigationDestination(for: AppRoute.self, destination: destination)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .library:
                    NavigationStack(path: coordinator.path(for: .library)) {
                        SavedVoicesView(projectID: nil)
                            .navigationDestination(for: AppRoute.self, destination: destination)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .activity:
                    NavigationStack(path: coordinator.path(for: .activity)) {
                        GenerationActivityView()
                            .navigationDestination(for: AppRoute.self, destination: destination)
                            .toolbar(.hidden, for: .navigationBar)
                    }
                case .settings:
                    tabStack(for: .settings, title: "Settings", milestone: "M11")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .ignoresSafeArea(.keyboard)
        .sheet(item: sheetBinding, content: sheetContent)
        .task {
            if dashboardViewModel == nil {
                dashboardViewModel = DashboardViewModel(
                    repository: SwiftDataDashboardRepository(context: modelContext)
                )
            }
        }
    }

    @ViewBuilder
    private var dashboardRoot: some View {
        if let viewModel = dashboardViewModel {
            DashboardView(viewModel: viewModel)
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.caBackground)
        }
    }

    private func tabStack(for tab: AppTab, title: String, milestone: String) -> some View {
        NavigationStack(path: coordinator.path(for: tab)) {
            DevelopmentPlaceholderView(title: title, milestone: milestone)
                .navigationDestination(for: AppRoute.self, destination: destination)
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .projectDetail(let id):
            ProjectOverviewView(projectID: id)
        case .newProject:
            NewProjectView()
        case .ideaGeneration(let projectID):
            IdeasView(projectID: projectID)
        case .ideaComparison(let projectID):
            IdeaComparisonView(projectID: projectID)
        case .outline(let projectID):
            OutlineView(projectID: projectID)
        case .chapterEdit(let chapterID):
            ChapterEditView(chapterID: chapterID)
        case .chapterList(let outlineID):
            ChapterListView(outlineID: outlineID)
        case .scriptChapters(let projectID):
            ScriptChapterListView(projectID: projectID)
        case .scriptReader(let chapterID):
            ScriptReaderView(chapterID: chapterID)
        case .chapterRevision(let chapterID):
            RevisionView(chapterID: chapterID)
        case .savedVoices(let projectID):
            SavedVoicesView(projectID: projectID)
        case .voiceDetail(let voiceID, let projectID):
            VoiceDetailView(voiceID: voiceID, projectID: projectID)
        case .voiceEdit(let voiceID):
            VoiceEditView(voiceID: voiceID)
        case .voiceCasting(let projectID):
            CastingView(projectID: projectID)
        case .voiceCreation(let projectID):
            VoiceCreationView(projectID: projectID)
        case .narrationStudio(let projectID):
            NarrationView(projectID: projectID)
        case .audioReview(let chapterID):
            AudioReviewView(chapterID: chapterID)
        case .soundCues(let projectID):
            SoundCuesView(projectID: projectID)
        case .cueDetail(let cueID):
            CueDetailView(cueID: cueID)
        case .narration(let projectID):
            NarrationView(projectID: projectID)
        case .reviewItem:
            DevelopmentPlaceholderView(title: "Review item", milestone: "M8/M9")
        case .reviewQueue:
            DevelopmentPlaceholderView(title: "Review queue", milestone: "M8")
        case .placeholder(let title, let milestone):
            DevelopmentPlaceholderView(title: title, milestone: milestone)
        }
    }

    // MARK: Bottom bar

    private var tabBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Color.caHairline)
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        coordinator.selectedTab = tab
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.title)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundStyle(tab == coordinator.selectedTab ? Color.caInk : Color.caSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Color.caSurface)
    }

    // MARK: Sheet plumbing

    private var sheetBinding: Binding<AppRoute?> {
        Binding(
            get: { coordinator.sheet },
            set: { coordinator.sheet = $0 }
        )
    }

    private func sheetContent(_ route: AppRoute) -> some View {
        NavigationStack { destination(route) }
    }
}
