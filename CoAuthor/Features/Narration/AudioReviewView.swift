import SwiftUI
import SwiftData

/// Audio review — "Listen & review." Player, source passage, paid
/// confirm-generation card, approve CTA.
/// Reference: Designs/Full Content/Audio review & generation confirmation
struct AudioReviewView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let chapterID: UUID
    @State private var viewModel: AudioReviewViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Review") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project,
                   let chapter = viewModel.chapter {
                    content(project, chapter, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load audio",
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
                let vm = AudioReviewViewModel(
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
        _ viewModel: AudioReviewViewModel
    ) -> some View {
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
                        Text("Listen & review")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    HStack(spacing: 8) {
                        StatusBadge(
                            "Generation: \(chapter.audioState == "ready" ? "Ready" : chapter.audioState.capitalized)",
                            kind: chapter.audioState == "ready" ? .warmLight : .neutral
                        )
                        StatusBadge(
                            "Review: \(chapter.reviewState)",
                            kind: chapter.reviewState == "Approved" ? .ready : .warm
                        )
                    }

                    playerCard(chapter, viewModel)
                    sourceCard(chapter)
                    if !viewModel.selectedBatch.isEmpty {
                        confirmGenerationCard(viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            audioStrip(chapter, viewModel)
            BottomCTA(title: viewModel.isApproved ? "Audio approved" : "Approve audio") {
                viewModel.approve()
            }
        }
    }

    // MARK: Player card

    private func playerCard(_ chapter: ScriptChapter, _ viewModel: AudioReviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Ready to listen")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Button {
                        viewModel.togglePlayback()
                    } label: {
                        Image(systemName: viewModel.isPlaying
                              ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.caInk)
                    }
                    .buttonStyle(.plain)
                }
                Text("\(viewModel.narratorName) · ElevenLabs · 1× speed")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Play / pause · scrub · −15 sec")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                ProgressView(
                    value: Double(viewModel.positionSeconds),
                    total: Double(max(chapter.audioSeconds, 1))
                )
                .tint(Color.caInk)
                HStack {
                    Text(ScriptReaderViewModel.format(viewModel.positionSeconds))
                    Spacer()
                    Text(ScriptReaderViewModel.format(chapter.audioSeconds))
                }
                .font(.caption)
                .foregroundStyle(Color.caSecondary)
                HStack(spacing: 10) {
                    Button {
                        coordinator.push(.placeholder(title: "Regenerate audio", milestone: "M12"))
                    } label: {
                        Text("Regenerate")
                    }
                    .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                    Button {
                        coordinator.push(.placeholder(title: "Download audio", milestone: "M10"))
                    } label: {
                        Text("Download")
                    }
                    .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Source passage

    private func sourceCard(_ chapter: ScriptChapter) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Source · 01:24–01:48")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Text("Script r\(chapter.revision)")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text(viewModelSourceExcerpt(chapter))
                    .font(.caSerif(15))
                    .lineSpacing(3)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.placeholder(title: "Performance correction", milestone: "M12"))
                } label: {
                    HStack(spacing: 6) {
                        Text("Add performance correction")
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

    private func viewModelSourceExcerpt(_ chapter: ScriptChapter) -> String {
        let paragraph = chapter.body.components(separatedBy: "\n\n").first ?? chapter.body
        return "\"\(paragraph)\""
    }

    // MARK: Confirm generation

    private func confirmGenerationCard(_ viewModel: AudioReviewViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Confirm generation")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Paid", kind: .warm)
                }
                Text(viewModel.batchSummary)
                    .font(.subheadline)
                    .foregroundStyle(Color.caInk)
                Text("\(viewModel.narratorName) · ElevenLabs · Script r4")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Estimated duration \(viewModel.batchEstimate)")
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Text("Estimate unavailable. Your connected account may be "
                     + "charged. Generation does not approve audio.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    viewModel.confirmGeneration()
                } label: {
                    HStack(spacing: 6) {
                        Text("Confirm generation")
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

    // MARK: Audio strip

    private func audioStrip(_ chapter: ScriptChapter, _ viewModel: AudioReviewViewModel) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.caInk)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(chapter.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("\(viewModel.narratorName) · ElevenLabs · 1×")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(ScriptReaderViewModel.format(viewModel.positionSeconds))
                Text(ScriptReaderViewModel.format(chapter.audioSeconds))
            }
            .font(.caption)
            .foregroundStyle(Color.caSecondary)
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, 6)
        .background(Color.caSurface)
    }
}
