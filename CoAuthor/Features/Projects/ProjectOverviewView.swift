import SwiftUI
import SwiftData

/// Project overview — first tab of a project's workspace.
/// Reference: Designs/Full Content/Project overview/Full Content.png
struct ProjectOverviewView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: ProjectOverviewViewModel?

    /// Sections of the project workspace; only Overview exists this
    /// milestone — the rest route to labeled placeholders.
    private let tabs: [(title: String, placeholder: (String, String)?)] = [
        ("Overview", nil),
        ("Story", ("Script", "M5")),
        ("Audio", ("Audio review", "M8")),
        ("Publish", ("Publishing kit", "M10")),
    ]

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Project") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't open project",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let vm = ProjectOverviewViewModel(
                    projectID: projectID,
                    repository: SwiftDataDashboardRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: ProjectOverviewViewModel) -> some View {
        VStack(spacing: 0) {
            tabStrip

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(project, viewModel)
                    storyCard(project, viewModel)
                    stagesCard(viewModel)
                    if let next = viewModel.recommendedNextStep {
                        nextStepCard(next)
                    }
                    activityCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.top, Theme.Spacing.cardGap)
                .padding(.bottom, Theme.Spacing.page)
            }

            BottomCTA(title: "Review chapter audio") {
                coordinator.push(.narration(projectID: project.id))
            }
        }
    }

    // MARK: Tab strip

    private var tabStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 24) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { pair in
                    let tab = pair.element
                    if let placeholder = tab.placeholder {
                        Button {
                            coordinator.push(.placeholder(title: placeholder.0, milestone: placeholder.1))
                        } label: {
                            tabItem(tab.title, active: false)
                        }
                        .buttonStyle(.plain)
                    } else {
                        tabItem(tab.title, active: true)
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

    // MARK: Content

    private func titleBlock(_ project: Project, _ viewModel: ProjectOverviewViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(project.title)
                .font(.caSerif(34))
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            HStack(spacing: 8) {
                if project.totalChapters > 0 {
                    overviewPill("\(project.narratedChapters) of \(project.totalChapters) narrated")
                }
                if project.cuesTotal > 0 {
                    overviewPill("\(project.cuesApproved) of \(project.cuesTotal) cues")
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func overviewPill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Color.caSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.caPill)
            .clipShape(Capsule())
    }

    private func storyCard(_ project: Project, _ viewModel: ProjectOverviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Your story")
                Text(project.premise)
                    .font(.body)
                if !viewModel.storyMeta.isEmpty {
                    Text(viewModel.storyMeta)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func stagesCard(_ viewModel: ProjectOverviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Production stages")
                ForEach(viewModel.productionStages) { stage in
                    HStack(spacing: 10) {
                        Image(systemName: stage.complete ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(stage.complete ? Color.caInk : Color.caSecondary)
                        Text(stage.label)
                            .font(.subheadline)
                            .foregroundStyle(stage.complete ? Color.caInk : Color.caSecondary)
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func nextStepCard(_ next: (title: String, detail: String)) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Recommended next step")
                HStack(alignment: .top, spacing: 10) {
                    Rectangle()
                        .fill(Color.caInk)
                        .frame(width: 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Label(next.title, systemImage: "exclamationmark.circle")
                            .font(.subheadline.weight(.semibold))
                        Text(next.detail)
                            .font(.footnote)
                            .foregroundStyle(Color.caSecondary)
                    }
                }
                Button {
                    coordinator.push(.placeholder(title: "Review assets", milestone: "M8"))
                } label: {
                    HStack(spacing: 4) {
                        Text("Review affected assets")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func activityCard(_ viewModel: ProjectOverviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("Recent activity")
                    .padding(.bottom, 8)
                ForEach(viewModel.activityEntries) { entry in
                    HStack {
                        Text(entry.title)
                            .font(.subheadline)
                        Spacer()
                        Text(entry.when)
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 6)
                }
                HStack(spacing: 16) {
                    pipelineLink("Documents", milestone: "M10")
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(Color.caSecondary)
                    pipelineLink("Script", milestone: "M5")
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(Color.caSecondary)
                    pipelineLink("Audio", milestone: "M8")
                }
                .padding(.top, 10)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func pipelineLink(_ title: String, milestone: String) -> some View {
        Button {
            coordinator.push(.placeholder(title: title, milestone: milestone))
        } label: {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "arrow.right")
                    .font(.caption2.weight(.semibold))
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.caInk)
        }
        .buttonStyle(.plain)
    }
}
