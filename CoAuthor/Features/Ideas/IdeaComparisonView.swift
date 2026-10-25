import SwiftUI
import SwiftData

/// Idea comparison / story setup — "Choose your story."
/// Reference: Designs/Full Content/Idea comparison & story setup/Full Content.png
struct IdeaComparisonView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: IdeasViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Compare") {
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
                    : .ideaGeneration(projectID: project.id),
                audioDestination: project.narratorConfirmed
                    ? .narrationStudio(projectID: project.id) : nil
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Choose your story.")
                            .font(.title.weight(.bold))
                        Text("Compare \(viewModel.selectedIdeas.count) ideas · Stacked for focused reading")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    ForEach(viewModel.selectedIdeas, id: \.id) { idea in
                        comparisonCard(idea, viewModel)
                    }

                    storyConfigCard(viewModel)
                    progressCard(project)
                    nextCard
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.top, Theme.Spacing.cardGap)
                .padding(.bottom, Theme.Spacing.page)
            }

            BottomCTA(title: "Select and generate outline") {
                if let chosen = viewModel.selectedIdeas.first(where: {
                    $0.id == viewModel.chosenIdeaID
                }) ?? viewModel.selectedIdeas.first {
                    viewModel.choose(chosen)
                }
                coordinator.push(.outline(projectID: project.id))
            }
        }
    }

    // MARK: Cards

    private func comparisonCard(_ idea: Idea, _ viewModel: IdeasViewModel) -> some View {
        let chosen = viewModel.chosenIdeaID == idea.id
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: chosen ? "checkmark.square.fill" : "circle")
                    .foregroundStyle(chosen ? Color.caInk : Color.caSecondary)
                Text(idea.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if chosen {
                    Text("Selected")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caInk)
                }
            }
            if chosen && !idea.tagline.isEmpty {
                Text(idea.tagline)
                    .font(.footnote)
                    .foregroundStyle(Color.caSecondary)
            }
            Text(idea.expandedPitch)
                .font(.subheadline)
            Button {
                if chosen {
                    coordinator.push(.placeholder(title: "Refine idea", milestone: "M12"))
                } else {
                    viewModel.choose(idea)
                }
            } label: {
                HStack(spacing: 4) {
                    Text(chosen ? "Refine selected idea" : "Select this idea")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.caSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(chosen ? Color.caInk : Color.caHairline,
                              lineWidth: chosen ? 2 : 1)
        )
    }

    private func storyConfigCard(_ viewModel: IdeasViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Story configuration")
                    .font(.subheadline.weight(.semibold))
                ForEach(Array(viewModel.storyConfigRows.enumerated()), id: \.offset) { pair in
                    HStack(alignment: .top) {
                        Text(pair.element.label)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                        Spacer(minLength: 16)
                        Text(pair.element.value)
                            .font(.subheadline.weight(.medium))
                            .multilineTextAlignment(.trailing)
                    }
                }
                Button {
                    coordinator.push(.placeholder(title: "Edit story configuration", milestone: "M4"))
                } label: {
                    HStack(spacing: 4) {
                        Text("Edit story configuration")
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func progressCard(_ project: Project) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Progress")
                    .font(.subheadline.weight(.semibold))
                HStack {
                    Text("Narration generated")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    Spacer()
                    StatusBadge(
                        "\(project.narratedChapters) of \(project.totalChapters) chapters",
                        kind: .warm
                    )
                }
                HStack {
                    Text("Cues reviewed")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    Spacer()
                    StatusBadge(
                        "\(project.cuesApproved) of \(project.cuesTotal) approved",
                        kind: .warm
                    )
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var nextCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text("Next: review your outline")
                    .font(.subheadline.weight(.semibold))
                Text("Characters, chapter arc and the private ending come first. Script generation waits for your approval.")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
