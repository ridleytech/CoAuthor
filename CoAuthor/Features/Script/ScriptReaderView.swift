import SwiftUI
import SwiftData

/// Script reader — serif chapter prose with revision/audio status.
/// Reference: Designs/Full Content/Script reader/Full Content.png
struct ScriptReaderView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let chapterID: UUID
    @State private var viewModel: ScriptReaderViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Script") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project,
                   let chapter = viewModel.chapter {
                    content(project, chapter, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load chapter",
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
                let vm = ScriptReaderViewModel(
                    chapterID: chapterID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ project: Project,
        _ chapter: ScriptChapter,
        _ viewModel: ScriptReaderViewModel
    ) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .story,
                storyDestination: .outline(projectID: project.id)
            )

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    titleBlock(chapter, viewModel)
                    if chapter.isAudioOutdated {
                        outdatedCard(chapter)
                    }
                    readerCard(chapter)
                    readerToolsCard(viewModel)
                    if viewModel.hasAudio {
                        audioStrip(chapter, viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }

            BottomCTA(title: "Edit chapter") {
                coordinator.push(.chapterRevision(chapterID: chapter.id))
            }
        }
    }

    private func titleBlock(_ chapter: ScriptChapter, _ viewModel: ScriptReaderViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chapter.title)
                .font(.caSerif(28))
                .foregroundStyle(Color.caInk)
            Text(viewModel.metaLine)
                .font(.subheadline)
                .foregroundStyle(Color.caSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // MARK: Outdated audio notice

    private func outdatedCard(_ chapter: ScriptChapter) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                StatusBadge("Outdated", kind: .warm)
                Text("This chapter changed after its audio was generated. "
                     + "Audio uses script r\(chapter.audioRevision ?? 0). "
                     + "Current script is r\(chapter.revision).")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.placeholder(title: "Affected assets", milestone: "M8"))
                } label: {
                    HStack(spacing: 6) {
                        Text("Review affected assets")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Reader card

    private func readerCard(_ chapter: ScriptChapter) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                Text(chapter.settingLabel.isEmpty
                     ? "READ" : "READ · \(chapter.settingLabel)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.caSecondary)
                    .tracking(0.4)
                ForEach(paragraphs(of: chapter), id: \.self) { paragraph in
                    Text(paragraph)
                        .font(.caSerif(17))
                        .lineSpacing(5)
                        .foregroundStyle(Color.caInk)
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func paragraphs(of chapter: ScriptChapter) -> [String] {
        chapter.body.components(separatedBy: "\n\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: Reader tools

    private func readerToolsCard(_ viewModel: ScriptReaderViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Reader tools")
                Button {
                    coordinator.push(.placeholder(title: "Revision history", milestone: "M12"))
                } label: {
                    HStack {
                        Text("Read / Edit · Search script · \(viewModel.revisionsLabel)")
                            .font(.subheadline)
                            .foregroundStyle(Color.caInk)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caInk)
                    }
                }
                .buttonStyle(.plain)
                Text("Production notes stay separate from the story.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Audio strip

    private func audioStrip(_ chapter: ScriptChapter, _ viewModel: ScriptReaderViewModel) -> some View {
        CardContainer {
            HStack(spacing: 12) {
                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.caInk)
                }
                .buttonStyle(.plain)
                VStack(alignment: .leading, spacing: 2) {
                    Text(chapter.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Text(viewModel.narratorLine)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Spacer()
                Text(viewModel.audioTimeLine)
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
