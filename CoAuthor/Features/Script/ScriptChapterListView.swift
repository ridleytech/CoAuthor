import SwiftUI
import SwiftData

/// Script chapter list — entry point to the script workspace after the
/// outline is approved. Generates a local draft on first open.
struct ScriptChapterListView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: ScriptViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Script") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load script",
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
                let vm = ScriptViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    outlineRepository: SwiftDataOutlineRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: ScriptViewModel) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .story,
                storyDestination: .outline(projectID: project.id)
            )
            if viewModel.chapters.isEmpty {
                ContentUnavailableView(
                    "No script yet",
                    systemImage: "doc.text",
                    description: Text("Approve the outline to generate a script draft.")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your script.")
                                .font(.caSerif(28))
                                .foregroundStyle(Color.caInk)
                            Text(viewModel.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(Color.caSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)

                        CardContainer {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.chapters) { chapter in
                                    chapterRow(chapter)
                                    if chapter.id != viewModel.chapters.last?.id {
                                        Divider().overlay(Color.caHairline)
                                    }
                                }
                            }
                            .padding(Theme.Spacing.card)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.page)
                    .padding(.vertical, Theme.Spacing.cardGap)
                }
            }
        }
    }

    private func chapterRow(_ chapter: ScriptChapter) -> some View {
        Button {
            coordinator.push(.scriptReader(chapterID: chapter.id))
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Text("\(chapter.number)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caSecondary)
                    .frame(width: 20, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    Text("\(chapter.wordCount) words"
                         + " · ~\(ScriptReaderViewModel.format(chapter.estimatedSeconds))"
                         + " · r\(chapter.revision)")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Spacer(minLength: 0)
                if chapter.isAudioOutdated {
                    StatusBadge("Outdated", kind: .warm)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
