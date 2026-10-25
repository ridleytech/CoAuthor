import SwiftUI
import SwiftData

/// Generated ideas — "Three ways into your story."
/// Reference: Designs/Full Content/Generated ideas/Full Content.png
struct IdeasView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: IdeasViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Ideas") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load ideas",
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
                let vm = IdeasViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    ideasRepository: SwiftDataIdeasRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: IdeasViewModel) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .story,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id)
                    : .ideaGeneration(projectID: project.id)
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(project, viewModel)

                    ForEach(viewModel.ideas, id: \.id) { idea in
                        ideaCard(idea, viewModel)
                    }

                    keepExploringCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.top, Theme.Spacing.cardGap)
                .padding(.bottom, Theme.Spacing.page)
            }

            BottomCTA(
                title: "Compare selected ideas",
                enabled: !viewModel.selectedIdeas.isEmpty
            ) {
                coordinator.push(.ideaComparison(projectID: project.id))
            }
        }
    }

    private func titleBlock(_ project: Project, _ viewModel: IdeasViewModel) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.title)
                .font(.title.weight(.bold))
            Text(viewModel.subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
            HStack(spacing: 8) {
                if project.totalChapters > 0 {
                    InfoPill("\(project.narratedChapters) of \(project.totalChapters) narrated")
                }
                if project.cuesTotal > 0 {
                    InfoPill("\(project.cuesApproved) of \(project.cuesTotal) cues approved")
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: Idea card

    private func ideaCard(_ idea: Idea, _ viewModel: IdeasViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(idea.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    selectionBadge(idea, viewModel)
                }

                Text(idea.pitch)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 4) {
                    labeledLine("Protagonist:", idea.protagonist)
                    labeledLine("Stakes:", idea.stakes)
                    labeledLine("Angle:", idea.angle)
                }

                HStack(spacing: 18) {
                    Button(idea.isSaved ? "Saved" : "Save") {
                        viewModel.toggleSaved(idea)
                    }
                    Button("Refine") {
                        coordinator.push(.placeholder(title: "Refine idea", milestone: "M12"))
                    }
                    Button {
                        coordinator.push(.ideaComparison(projectID: idea.projectID))
                    } label: {
                        HStack(spacing: 4) {
                            Text("View idea")
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.caInk)
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func selectionBadge(_ idea: Idea, _ viewModel: IdeasViewModel) -> some View {
        Button { viewModel.toggleSelected(idea) } label: {
            if idea.isSelected {
                Label("Selected", systemImage: "checkmark.square.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caInk)
            } else {
                Text("New idea")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.caPill)
                    .clipShape(Capsule())
            }
        }
        .buttonStyle(.plain)
    }

    private func labeledLine(_ label: String, _ value: String) -> some View {
        Text(label + " ")
            .font(.subheadline.weight(.semibold))
        + Text(value)
            .font(.subheadline)
    }

    private func keepExploringCard(_ viewModel: IdeasViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Keep exploring")
                    .font(.subheadline.weight(.semibold))
                Text("Your original premise is saved. Generate more ideas, refine this set, or use your original premise unchanged.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    viewModel.generateMore()
                } label: {
                    HStack(spacing: 4) {
                        Text("Generate more ideas")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
