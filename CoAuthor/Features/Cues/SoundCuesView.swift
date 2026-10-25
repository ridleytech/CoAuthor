import SwiftUI
import SwiftData

/// Sound-cues list — filter card, cue cards with review/generation
/// badges, batch selection, "Generate selected cues" CTA.
/// Reference: Designs/Full Content/Sound cues/Full Content.png
struct SoundCuesView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: CuesViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Sound cues") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load sound cues",
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
                let vm = CuesViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    cueRepository: SwiftDataCueRepository(context: modelContext),
                    scriptRepository: SwiftDataScriptRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: CuesViewModel) -> some View {
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
                        Text("Sound cues")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.caInk)
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    filterCard(viewModel)
                    ForEach(viewModel.visibleCues) { cue in
                        cueCard(cue, viewModel)
                    }
                    if viewModel.hiddenCount > 0 {
                        moreCard(viewModel)
                    } else {
                        eligibilityNote
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(
                title: "Generate selected cues",
                enabled: !viewModel.selectedCues.isEmpty
            ) {
                viewModel.generateSelected()
            }
        }
    }

    // MARK: Filter card

    private func filterCard(_ viewModel: CuesViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    filterMenu(
                        title: viewModel.chapterFilter,
                        options: viewModel.chapterOptions
                    ) { viewModel.chapterFilter = $0 }
                    Spacer()
                    Button("Select approved") {
                        viewModel.selectApproved()
                    }
                    .buttonStyle(CAPrimaryButtonStyle())
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterMenu(
                            title: viewModel.importanceFilter,
                            options: viewModel.importanceOptions
                        ) { viewModel.importanceFilter = $0 }
                        filterMenu(
                            title: viewModel.reviewFilter,
                            options: viewModel.reviewOptions
                        ) { viewModel.reviewFilter = $0 }
                        filterMenu(
                            title: viewModel.generationFilter,
                            options: viewModel.generationOptions
                        ) { viewModel.generationFilter = $0 }
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func filterMenu(
        title: String,
        options: [String],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(option) { onSelect(option) }
            }
        } label: {
            HStack(spacing: 4) {
                Text(title)
                    .font(.caption.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(Color.caInk)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.caField)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: Cue card

    private func cueCard(_ cue: SoundCue, _ viewModel: CuesViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        coordinator.push(.cueDetail(cueID: cue.id))
                    } label: {
                        Text("\(cue.code) · \(cue.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    if cue.isSelected {
                        Button {
                            viewModel.toggleSelection(cue)
                        } label: {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.caInk)
                                .frame(width: 24, height: 24)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Deselect cue")
                    }
                }
                HStack(spacing: 6) {
                    reviewBadge(cue)
                    generationBadge(cue)
                }
                Text("\(cue.chapterTitle) · \(cue.importance) · \(cue.category)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                if !cue.sourcePassage.isEmpty {
                    Text(cue.sourcePassage)
                        .font(.footnote)
                        .foregroundStyle(Color.caInk)
                }
                actionRow(cue)
            }
            .padding(Theme.Spacing.card)
        }
    }

    @ViewBuilder
    private func reviewBadge(_ cue: SoundCue) -> some View {
        switch cue.reviewState {
        case "Approved":
            StatusBadge("Approved", kind: .ready)
        case "Skipped":
            StatusBadge("Skipped", kind: .neutral)
        default:
            StatusBadge("Suggested", kind: .warm)
        }
    }

    @ViewBuilder
    private func generationBadge(_ cue: SoundCue) -> some View {
        switch cue.generationState {
        case "Ready":
            StatusBadge("Ready", kind: .ready)
        case "Queued":
            StatusBadge("Queued", kind: .info)
        case "No audio file needed":
            StatusBadge("No audio file needed", kind: .neutral)
        default:
            StatusBadge("Not generated", kind: .neutral)
        }
    }

    private func actionRow(_ cue: SoundCue) -> some View {
        Button {
            coordinator.push(.cueDetail(cueID: cue.id))
        } label: {
            HStack(spacing: 4) {
                if cue.isSilence {
                    Text("Review silence cue")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.medium))
                } else {
                    Text("Source  /  Placement  /  Edit")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.medium))
                }
            }
            .foregroundStyle(Color.caInk)
        }
        .buttonStyle(.plain)
    }

    // MARK: Footer cards

    private func moreCard(_ viewModel: CuesViewModel) -> some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(viewModel.hiddenCount) more cues")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Text("Silence cues can be approved but never generate "
                         + "audio. Only approved audio cues are eligible "
                         + "for batch generation.")
                        .font(.footnote)
                        .foregroundStyle(Color.caSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button("Load") {
                    viewModel.showAll()
                }
                .buttonStyle(CAPrimaryButtonStyle())
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var eligibilityNote: some View {
        CardContainer {
            Text("Silence cues can be approved but never generate "
                 + "audio. Only approved audio cues are eligible "
                 + "for batch generation.")
                .font(.footnote)
                .foregroundStyle(Color.caSecondary)
                .padding(Theme.Spacing.card)
        }
    }
}
