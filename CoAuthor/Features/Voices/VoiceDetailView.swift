import SwiftUI
import SwiftData

/// Saved voice detail & casting picker — capacity, narrator card,
/// audition strip, design prompt, local metadata, remove/manage.
/// Reference: Designs/Full Content/Saved Voice detail & casting picker
struct VoiceDetailView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let voiceID: UUID
    let projectID: UUID?
    @State private var viewModel: VoiceDetailViewModel?

    var body: some View {
        VStack(spacing: 0) {
            BackTopBar(title: viewModel?.contextProject?.title ?? "Voice") {
                coordinator.pop()
            }
            Group {
                if let viewModel, let project = viewModel.contextProject,
                   let voice = viewModel.voice {
                    content(project, voice, viewModel)
                } else if let viewModel, let voice = viewModel.voice {
                    contentNoContext(voice, viewModel)
                } else if let error = viewModel?.loadError {
                    ContentUnavailableView(
                        "Couldn't load voice",
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
                let vm = VoiceDetailViewModel(
                    voiceID: voiceID,
                    projectID: projectID,
                    projectsRepository: projectID == nil
                        ? nil
                        : SwiftDataDashboardRepository(context: modelContext),
                    voiceRepository: SwiftDataVoiceRepository(context: modelContext)
                )
                viewModel = vm
                vm.load()
            }
        }
    }

    @ViewBuilder
    private func content(
        _ project: Project,
        _ voice: Voice,
        _ viewModel: VoiceDetailViewModel
    ) -> some View {
        VStack(spacing: 0) {
            ProjectSectionTabs(
                projectID: project.id,
                active: .audio,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id) : nil
            )
            detailScroll(voice, viewModel)
            BottomCTA(title: "Use this voice — \(project.title)") {
                viewModel.useThisVoice()
                coordinator.pop()
            }
        }
    }

    @ViewBuilder
    private func contentNoContext(_ voice: Voice, _ viewModel: VoiceDetailViewModel) -> some View {
        detailScroll(voice, viewModel)
    }

    private func detailScroll(_ voice: Voice, _ viewModel: VoiceDetailViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.name)
                        .font(.caSerif(28))
                        .foregroundStyle(Color.caInk)
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.vertical, 4)

                HStack(spacing: 8) {
                    if voice.isAvailable {
                        Label("Available", systemImage: "checkmark")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.caInk)
                    }
                    Text("\(voice.origin) · \(voice.kind) voice · ElevenLabs")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }

                VoiceCapacityCard(capacity: viewModel.capacity)
                narratorCard(voice, viewModel)
                VoiceAuditionStrip(
                    title: "\(voice.name) · audition",
                    position: "00:08",
                    duration: voice.sampleSeconds > 0
                        ? ScriptReaderViewModel.format(voice.sampleSeconds) : "0:00",
                    isPlaying: viewModel.isPlaying
                ) {
                    viewModel.togglePlayback()
                }
                designPromptCard(voice)
                localMetadataCard(voice)
                removeCard()
                manageCard()
            }
            .padding(.horizontal, Theme.Spacing.page)
            .padding(.vertical, Theme.Spacing.cardGap)
        }
    }

    // MARK: Narrator card

    private func narratorCard(_ voice: Voice, _ viewModel: VoiceDetailViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(voice.descriptor.isEmpty ? "Narrator" : voice.descriptor.capitalized,
                          systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    if voice.isFavorite {
                        StatusBadge("Favorited", kind: .warmLight)
                    }
                }
                Text(voice.summary)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Text(voice.tags.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Sample: \(voice.sampleSeconds > 0 ? ScriptReaderViewModel.format(voice.sampleSeconds) : "not generated") · ElevenLabs")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Reusing this existing voice consumes no additional "
                     + "custom voice slot.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                HStack(spacing: 8) {
                    Button {
                        viewModel.toggleFavorite()
                    } label: {
                        Label("Favorite", systemImage: "star")
                    }
                    .buttonStyle(CASecondaryButtonStyle())
                    Button("Set default narrator") {
                        viewModel.useThisVoice()
                    }
                    .buttonStyle(CASecondaryButtonStyle())
                }
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Design prompt

    private func designPromptCard(_ voice: Voice) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Original design prompt")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(voice.designPrompt)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                Text("Saved voice ID: \(voice.savedVoiceID)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Local metadata

    private func localMetadataCard(_ voice: Voice) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 6) {
                Text("Local name, labels & notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text(voice.localName.isEmpty ? voice.displayName : voice.localName)
                    .font(.subheadline)
                if !voice.localLabels.isEmpty {
                    Text(voice.localLabels)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                if !voice.localNotes.isEmpty {
                    Text(voice.localNotes)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text(voice.assignmentLabel.isEmpty
                     ? "Assignment: none"
                     : "Assignment: \(voice.assignmentLabel)")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.voiceEdit(voiceID: voice.id))
                } label: {
                    HStack {
                        Text("Edit local entry")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.caField)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Remove / manage

    private func removeCard() -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Remove from CoAuthor")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("This removes only the local reference entry. It does "
                     + "NOT delete the voice at ElevenLabs or free a provider "
                     + "slot. The provider voice can still appear in "
                     + "\"All account voices\".")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    viewModel?.removeFromCoAuthor()
                    coordinator.pop()
                } label: {
                    HStack {
                        Text("Remove from CoAuthor")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.caField)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func manageCard() -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                Text("Manage ElevenLabs Voices")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Provider deletion is available only for voices the "
                     + "account is permitted to delete. Deleting a voice "
                     + "requires confirmation and lists affected assignments. "
                     + "Previously generated audio remains accessible.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.placeholder(title: "Manage ElevenLabs voices", milestone: "M12"))
                } label: {
                    HStack {
                        Text("Manage ElevenLabs Voices")
                            .font(.caption.weight(.medium))
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Color.caInk)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.caField)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(Theme.Spacing.card)
        }
    }
}
