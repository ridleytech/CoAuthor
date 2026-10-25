import SwiftUI
import SwiftData

/// Voices & casting detail — "Find your narrator." Narrator suggestion,
/// voice design prompt, audition direction, cast assignments.
/// Reference: Designs/Full Content/Voices & casting detail
struct CastingView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID
    @State private var viewModel: CastingViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.project?.title ?? "Voices") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.project {
                    content(project, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load casting",
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
                let vm = CastingViewModel(
                    projectID: projectID,
                    projectsRepository: SwiftDataDashboardRepository(context: modelContext),
                    voiceRepository: SwiftDataVoiceRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(_ project: Project, _ viewModel: CastingViewModel) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .audio,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id) : nil
            )
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Find your narrator.")
                            .font(.caSerif(28))
                            .foregroundStyle(Color.caInk)
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    .padding(.vertical, 4)

                    VoiceCapacityCard(capacity: viewModel.capacity)
                    createOrChooseButtons
                    reusingNote
                    suggestionCard(viewModel)
                    auditionCard(viewModel)
                    designPromptCard(viewModel)
                    auditionDirectionCard(viewModel)
                    castAssignmentsCard(viewModel)
                    castingContextCard
                    createOrChooseButtons
                    manageRows
                    approvalNote
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(
                title: viewModel.isPromptApproved
                    ? "Voice description approved"
                    : "Approve voice description",
                enabled: !viewModel.isPromptApproved
            ) {
                viewModel.approveDescription()
            }
        }
    }

    // MARK: Create / choose buttons

    private var createOrChooseButtons: some View {
        VStack(spacing: 8) {
            Button {
                coordinator.push(.placeholder(title: "Create voice", milestone: "M7"))
            } label: {
                Text("Create New Voice")
            }
            .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
            Button {
                if let projectID = viewModel?.projectID {
                    coordinator.push(.savedVoices(projectID: projectID))
                }
            } label: {
                Text("Choose Saved Voice")
            }
            .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))
        }
    }

    private var reusingNote: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reusing an existing voice")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Choosing a saved voice consumes no additional "
                     + "custom voice slot.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Suggestion

    private func suggestionCard(_ viewModel: CastingViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.suggestionTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                        Text("Series narrator · Single voice")
                            .font(.caption)
                            .foregroundStyle(Color.caSecondary)
                    }
                    Spacer()
                    StatusBadge("Suggested", kind: .warm)
                }
                Text(viewModel.suggestionDetail)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                HStack {
                    StatusBadge("Not generated", kind: .neutral)
                    Spacer()
                    Button {
                        if let projectID = viewModel.project?.id {
                            coordinator.push(.savedVoices(projectID: projectID))
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("Choose a voice")
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Audition sample

    private func auditionCard(_ viewModel: CastingViewModel) -> some View {
        CardContainer {
            HStack(spacing: 12) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.caInk)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audition sample")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Text("Not generated · ElevenLabs Voice Design")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Spacer()
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Design prompt

    private func designPromptCard(_ viewModel: CastingViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Voice Design prompt")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    Button {
                        coordinator.push(.placeholder(title: "Edit voice prompt", milestone: "M7"))
                    } label: {
                        HStack(spacing: 4) {
                            Text("Edit")
                            Image(systemName: "arrow.right")
                        }
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.caInk)
                    }
                }
                Text(viewModel.voiceDesignPrompt)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Audition direction

    private func auditionDirectionCard(_ viewModel: CastingViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Audition & performance")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(viewModel.auditionDirection)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Cast assignments

    private func castAssignmentsCard(_ viewModel: CastingViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cast assignments")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                if viewModel.assignments.isEmpty {
                    Text("No cast assignments yet.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                } else {
                    ForEach(viewModel.assignments) { assignment in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(assignment.characterName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.caInk)
                                Text(assignment.roleLabel)
                                    .font(.caption)
                                    .foregroundStyle(Color.caSecondary)
                            }
                            Spacer()
                            StatusBadge(
                                assignment.approved ? "Approved" : "Suggested",
                                kind: assignment.approved ? .warm : .warmLight
                            )
                        }
                    }
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Casting context / manage rows / approval note

    private var castingContextCard: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text("Casting context")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("This is a single-narrator project. Separate generated "
                     + "character voices are not required. Character "
                     + "descriptions guide one narrator.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private var manageRows: some View {
        VStack(spacing: 0) {
            Button {
                coordinator.push(.savedVoices(projectID: nil))
            } label: {
                manageRow("Manage Voices")
            }
            Divider().overlay(Color.caHairline)
            Button {
                coordinator.push(.placeholder(title: "ElevenLabs plan", milestone: "M11"))
            } label: {
                manageRow("View ElevenLabs Plan")
            }
        }
        .background(Color.caSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Color.caHairline, lineWidth: 1)
        )
    }

    private func manageRow(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Color.caInk)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.caSecondary)
        }
        .padding(Theme.Spacing.card)
        .contentShape(Rectangle())
    }

    private var approvalNote: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Approval ≠ paid generation")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Approving saves the voice description only. Paid "
                     + "preview generation requires separate confirmation. "
                     + "Estimated credit usage: Not available. Saving a "
                     + "provider voice and assigning it are separate steps.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
