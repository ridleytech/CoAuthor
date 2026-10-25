import SwiftUI
import SwiftData

/// Narration studio — "Chapter recordings." Narrator summary,
/// per-chapter generation states, selection, batch generate CTA.
/// Reference: Designs/Full Content/Narration studio/Full Content.png
struct NarrationView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: NarrationViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Narration") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load narration",
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
                let vm = NarrationViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: NarrationViewModel) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .audio,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id) : nil,
                audioDestination: project.narratorConfirmed
                    ? .narrationStudio(projectID: project.id) : nil
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chapter recordings")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    narratorCard(project, viewModel)
                    ForEach(viewModel.chapters) { chapter in
                        chapterCard(chapter, viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            if let playing = viewModel.playingChapter, playing.audioSeconds > 0 {
                playerStrip(playing, viewModel)
            }
            BottomCTA(
                title: "Generate selected chapters",
                enabled: viewModel.hasSelection
            ) {
                if let chapter = viewModel.chapterForReview() {
                    coordinator.push(.audioReview(chapterID: chapter.id))
                }
            }
        }
    }

    // MARK: Narrator card

    private func narratorCard(_ project: Project, _ viewModel: NarrationViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Narrator confirmed · \(viewModel.narratorName)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Confirmed", kind: .warmLight)
                }
                Text("Script revision \(project.scriptRevision) · Single narrator")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                if viewModel.hasSelection {
                    Text("☑ \(viewModel.selectionSummary)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caInk)
                    Text("Estimated audio: \(viewModel.selectionEstimate)")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                Button {
                    coordinator.push(.voiceCasting(projectID: project.id))
                } label: {
                    HStack(spacing: 6) {
                        Text("Change narrator / selection")
                            .font(.subheadline.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                }
                Button {
                    coordinator.push(.soundCues(projectID: project.id))
                } label: {
                    HStack(spacing: 6) {
                        Text("Sound cues")
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

    // MARK: Chapter card

    private func chapterCard(_ chapter: ScriptChapter, _ viewModel: NarrationViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        viewModel.toggleSelection(chapter)
                    } label: {
                        Image(systemName: chapter.isSelectedForGeneration
                              ? "checkmark.square.fill" : "square")
                            .font(.body)
                            .foregroundStyle(
                                chapter.isSelectedForGeneration
                                    ? Color.caInk : Color.caSecondary
                            )
                            .accessibilityLabel(chapter.isSelectedForGeneration
                                                ? "Deselect chapter"
                                                : "Select chapter")
                    }
                    .buttonStyle(.plain)
                    Text("\(chapter.number). \(chapter.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    if chapter.isSelectedForGeneration {
                        Text("Selected")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.caSurface)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.caInk)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    Spacer()
                }
                Text("\(viewModel.narratorName) · Script r\(chapter.revision)"
                     + " · ~\(ScriptReaderViewModel.format(chapter.estimatedSeconds))")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                HStack(spacing: 6) {
                    statusBadges(chapter)
                }
                actionRow(chapter, viewModel)
            }
            .padding(Theme.Spacing.card)
        }
    }

    @ViewBuilder
    private func statusBadges(_ chapter: ScriptChapter) -> some View {
        switch chapter.audioState {
        case "ready":
            if chapter.isAudioOutdated {
                StatusBadge("Outdated", kind: .warm)
            } else {
                StatusBadge("● Ready", kind: .ready)
            }
        case "queued":
            StatusBadge("Queued", kind: .neutral)
        case "generating":
            StatusBadge("↻ Generating", kind: .info)
        case "failed":
            StatusBadge("Failed", kind: .failed)
        case "canceled":
            StatusBadge("Canceled", kind: .neutral)
        default:
            StatusBadge("· Not generated", kind: .neutral)
        }
        if chapter.reviewState == "Approved" {
            StatusBadge("✓ Approved", kind: .ready)
        } else {
            StatusBadge("Review: \(chapter.reviewState)", kind: .warmLight)
        }
    }

    @ViewBuilder
    private func actionRow(_ chapter: ScriptChapter, _ viewModel: NarrationViewModel) -> some View {
        switch chapter.audioState {
        case "ready":
            chapterLink("Listen / Review") {
                coordinator.push(.audioReview(chapterID: chapter.id))
            }
        case "queued", "generating":
            chapterLink("Cancel job") {
                viewModel.cancelJob(chapter)
            }
        case "failed":
            chapterLink("Retry") {
                viewModel.retry(chapter)
            }
        default:
            chapterLink("Select chapter") {
                viewModel.selectForGeneration(chapter)
            }
        }
    }

    private func chapterLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.caInk)
        }
    }

    // MARK: Player strip

    private func playerStrip(_ chapter: ScriptChapter, _ viewModel: NarrationViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.caInk)
                    .accessibilityLabel(viewModel.isPlaying ? "Pause" : "Play")
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("\(ScriptReaderViewModel.format(chapter.audioPosition)) "
                     + "—— \(ScriptReaderViewModel.format(chapter.audioSeconds))")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer()
            Text("1×")
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, 6)
        .background(Color.caSurface)
    }
}
