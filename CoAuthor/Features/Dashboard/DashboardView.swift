import SwiftUI
import SwiftData

/// Projects dashboard — first screen of the app.
/// Reference: Designs/Full Content/Dashboard/Full Content.png
struct DashboardView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 0) {
            BrandTopBar()
            ScrollView {
                if viewModel.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .background(Color.caBackground)
            BottomCTA(title: "New project") { coordinator.push(.newProject) }
        }
        .background(Color.caBackground)
        .onAppear { viewModel.load() }
    }

    // MARK: Scrollable content

    private var content: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
            titleBlock

            if let featured = viewModel.featured {
                ContinueCard(
                    project: featured,
                    editedDescription: viewModel.editedDescription(for: featured),
                    onContinue: { coordinator.push(.narration(projectID: featured.id)) },
                    onOpen: { coordinator.push(.projectDetail(featured.id)) }
                )

                statsRow(featured)
            }

            if !viewModel.recentProjects.isEmpty {
                recentProjectsCard
            }

            if !viewModel.previewReviewItems.isEmpty {
                reviewQueueCard
            }
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.top, Theme.Spacing.cardGap)
        .padding(.bottom, Theme.Spacing.page)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                Text("Your stories")
                    .font(.title.weight(.bold))
                Spacer()
                Button("New project") { coordinator.push(.newProject) }
                    .buttonStyle(CAPrimaryButtonStyle())
            }
            Text("Welcome back, \(viewModel.welcomeName) · \(viewModel.projects.count) projects")
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .padding(.vertical, 4)
    }

    private func statsRow(_ project: Project) -> some View {
        HStack(spacing: 10) {
            StatTile(
                label: "Narration",
                value: "\(project.narratedChapters) / \(project.totalChapters)",
                sublabel: "chapters"
            )
            StatTile(
                label: "Runtime",
                value: "~\(project.runtimeTargetMinutes) min",
                sublabel: "target"
            )
            StatTile(
                label: "Last edit",
                value: DashboardViewModel.timeFormatter.string(from: project.lastEditedAt),
                sublabel: viewModel.editedDayLabel(for: project)
            )
        }
    }

    private var recentProjectsCard: some View {
        ListCard(
            title: "Recent projects",
            trailing: "\(viewModel.remainingProjectCount) more"
        ) {
            ForEach(Array(viewModel.recentProjects.enumerated()), id: \.element.id) { pair in
                if pair.offset > 0 { Divider().overlay(Color.caHairline).padding(.horizontal, Theme.Spacing.card) }
                Button { coordinator.push(.projectDetail(pair.element.id)) } label: {
                    ProjectRow(
                        project: pair.element,
                        editedDescription: viewModel.editedDescription(for: pair.element)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var reviewQueueCard: some View {
        ListCard(
            title: "Review queue",
            trailing: "\(viewModel.reviewItems.count) items"
        ) {
            ForEach(Array(viewModel.previewReviewItems.enumerated()), id: \.element.id) { pair in
                if pair.offset > 0 { Divider().overlay(Color.caHairline).padding(.horizontal, Theme.Spacing.card) }
                Button { coordinator.push(.reviewItem(pair.element.id)) } label: {
                    ReviewItemRow(item: pair.element)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.cardGap) {
            titleBlock
            CardContainer {
                VStack(spacing: 10) {
                    Text("No stories yet")
                        .font(.headline)
                    Text("Start a project and CoAuthor will help you shape it into an audiobook.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                        .multilineTextAlignment(.center)
                    Button("New project") { coordinator.push(.newProject) }
                        .buttonStyle(CAPrimaryButtonStyle())
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.card)
            }
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.top, Theme.Spacing.cardGap)
    }
}

#Preview {
    let schema = CoAuthorSchema.current
    let container = try! ModelContainer(
        for: schema,
        configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
    )
    SampleData.insertSamples(into: container.mainContext)
    return NavigationStack {
        DashboardView(
            viewModel: DashboardViewModel(
                repository: SwiftDataDashboardRepository(context: container.mainContext)
            )
        )
    }
    .environment(AppCoordinator())
}
