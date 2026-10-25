import SwiftUI
import SwiftData

/// Cue detail — exact source passage, placement & mixing (editable),
/// generation prompt review, alternative comparison, batch
/// confirmation. Silence cues show a reduced detail.
/// Reference: Designs/Full Content/Cue detail, edit & audition
/// alternatives/Full Content.png
struct CueDetailView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let cueID: UUID
    @State private var viewModel: CueDetailViewModel?
    @State private var isEditingPlacement = false
    @State private var placementDraft = ""

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Cue") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project,
                   let cue = viewModel.cue {
                    content(project, cue, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load the cue",
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
                let vm = CueDetailViewModel(
                    cueID: cueID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ project: Project,
        _ cue: SoundCue,
        _ viewModel: CueDetailViewModel
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
                        Text(cue.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                        HStack(spacing: 6) {
                            if cue.reviewState == "Approved" {
                                StatusBadge("✓ Approved", kind: .ready)
                            } else if cue.reviewState == "Skipped" {
                                StatusBadge("Skipped", kind: .neutral)
                            }
                            generationBadge(cue)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)

                    sourcePassageCard(cue)
                    placementCard(cue, viewModel)
                    if cue.isSilence {
                        silenceNoteCard
                    } else {
                        promptCard(cue, viewModel)
                        alternativesCard(cue, viewModel)
                        batchCard(viewModel)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            if !cue.isSilence {
                playerStrip(cue, viewModel)
                BottomCTA(title: "Select preferred sound") {
                    coordinator.pop()
                }
            }
        }
    }

    // MARK: Cards

    private func sourcePassageCard(_ cue: SoundCue) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Exact source passage")
                Text(cue.sourcePassage)
                    .font(.callout)
                    .foregroundStyle(Color.caInk)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func placementCard(
        _ cue: SoundCue,
        _ viewModel: CueDetailViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Placement & mixing")
                if isEditingPlacement {
                    TextEditor(text: $placementDraft)
                        .font(.callout)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.caField)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                    HStack(spacing: 10) {
                        Button("Done") {
                            viewModel.updatePlacement(placementDraft)
                            isEditingPlacement = false
                        }
                        .buttonStyle(CAPrimaryButtonStyle())
                        Button("Cancel") {
                            isEditingPlacement = false
                        }
                        .buttonStyle(CASecondaryButtonStyle())
                    }
                } else {
                    if cue.placementText.isEmpty {
                        Text("No placement instructions yet.")
                            .font(.callout)
                            .foregroundStyle(Color.caSecondary)
                    } else {
                        Text(cue.placementText)
                            .font(.callout)
                            .foregroundStyle(Color.caInk)
                    }
                    detailLink("Edit cue instructions") {
                        placementDraft = cue.placementText
                        isEditingPlacement = true
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var silenceNoteCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel("Silence cue")
                Text("Deliberate silence — no audio file is generated "
                     + "for this cue. Silence cues can be approved but "
                     + "are excluded from batch generation.")
                    .font(.callout)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func promptCard(
        _ cue: SoundCue,
        _ viewModel: CueDetailViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    SectionLabel("Generation prompt")
                    Spacer()
                    generationBadge(cue)
                }
                if cue.generationPrompt.isEmpty {
                    Text("No generation prompt yet.")
                        .font(.callout)
                        .foregroundStyle(Color.caSecondary)
                } else {
                    Text(cue.generationPrompt)
                        .font(.callout)
                        .foregroundStyle(Color.caInk)
                }
                HStack(spacing: 10) {
                    promptAction("Approve") { viewModel.approve() }
                    promptAction("Reject") { viewModel.reject() }
                    promptAction("Skip") { viewModel.skip() }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func promptAction(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.caInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func alternativesCard(
        _ cue: SoundCue,
        _ viewModel: CueDetailViewModel
    ) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel("Compare alternatives")
                ForEach(
                    Array(cue.alternativeLabels.enumerated()),
                    id: \.offset
                ) { pair in
                    alternativeRow(
                        pair.element,
                        selected: cue.selectedAlternative == pair.offset
                    ) {
                        viewModel.selectAlternative(pair.offset)
                    }
                }
                detailLink("Play / Compare / Use existing") {
                    coordinator.push(.placeholder(
                        title: "Sound asset libraries",
                        milestone: "M10"
                    ))
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func alternativeRow(
        _ label: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                    .font(.caption)
                    .foregroundStyle(selected ? Color.caSurface : Color.caInk)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.subheadline.weight(.semibold))
                    Text(selected ? "00:30 · Selected" : "00:30")
                        .font(.caption)
                        .opacity(selected ? 0.8 : 1)
                }
                .foregroundStyle(selected ? Color.caSurface : Color.caInk)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caSurface)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.caInk : Color.caField)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.button,
                    style: .continuous
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func batchCard(_ viewModel: CueDetailViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SectionLabel("Batch confirmation")
                    Spacer()
                    Text("ElevenLabs · Estimate unavailable")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text(viewModel.batchSummary)
                    .font(.callout)
                    .foregroundStyle(Color.caInk)
                detailLink("Confirm sound generation") {
                    viewModel.confirmGeneration()
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Shared pieces

    @ViewBuilder
    private func generationBadge(_ cue: SoundCue) -> some View {
        switch cue.generationState {
        case "Ready":
            StatusBadge("Ready to generate", kind: .ready)
        case "Queued":
            StatusBadge("Queued", kind: .info)
        default:
            StatusBadge("Not generated", kind: .neutral)
        }
    }

    private func detailLink(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "arrow.right")
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(Color.caInk)
        }
        .buttonStyle(.plain)
    }

    private func playerStrip(
        _ cue: SoundCue,
        _ viewModel: CueDetailViewModel
    ) -> some View {
        HStack(spacing: 12) {
            Button {
                viewModel.togglePlayback()
            } label: {
                Image(systemName: viewModel.isPlaying
                      ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.caInk)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(cue.title) · Take "
                     + (cue.selectedAlternative == 0 ? "A" : "B"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("00:00 —— 00:30")
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
