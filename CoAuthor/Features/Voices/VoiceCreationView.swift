import SwiftUI
import SwiftData

/// Voice creation & casting — a 4-step flow (Describe → Previews →
/// Save → Assign) plus an assignment-success state. Steps render
/// inside one pushed screen so draft state stays in the view model.
/// References: Voice Capacity/Create Voice — Describe, Audition
/// alternatives & paid confirmation, Save Voice — Confirmation sheet,
/// Assign new saved voice, Existing voice — Assignment success.
struct VoiceCreationView: View {
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.modelContext) private var modelContext

    let projectID: UUID?
    @State private var viewModel: VoiceCreationViewModel?

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if let viewModel {
                    flowContent(viewModel)
                } else if let error = viewModel?.loadError {
                    VStack(spacing: 0) {
                        BackTopBar(title: "CoAuthor") { coordinator.pop() }
                        ContentUnavailableView(
                            "Couldn't start voice creation",
                            systemImage: "exclamationmark.triangle",
                            description: Text(error)
                        )
                    }
                } else {
                    BackTopBar(title: "CoAuthor") { coordinator.pop() }
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .background(Color.caBackground)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if viewModel == nil {
                let vm = VoiceCreationViewModel(
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

    // MARK: Flow shell

    @ViewBuilder
    private func flowContent(_ viewModel: VoiceCreationViewModel) -> some View {
        let showsTabs = viewModel.step == .previews || viewModel.step == .assign
            || viewModel.finished
        BackTopBar(title: headerTitle(viewModel), statusText: headerStatus(viewModel)) {
            stepBack(viewModel)
        }
        if showsTabs, let project = viewModel.project {
            ProjectSectionTabs(
                projectID: project.id,
                active: .audio,
                storyDestination: project.hasOutline
                    ? .outline(projectID: project.id) : nil,
                audioDestination: project.narratorConfirmed
                    ? .narrationStudio(projectID: project.id) : nil
            )
        }
        if viewModel.finished {
            successContent(viewModel)
        } else {
            switch viewModel.step {
            case .describe: describeContent(viewModel)
            case .previews: previewsContent(viewModel)
            case .save: saveContent(viewModel)
            case .assign: assignContent(viewModel)
            }
        }
    }

    private func headerTitle(_ viewModel: VoiceCreationViewModel) -> String {
        switch viewModel.step {
        case .describe, .save: "CoAuthor"
        case .previews, .assign:
            viewModel.project?.title ?? "CoAuthor"
        }
    }

    private func headerStatus(_ viewModel: VoiceCreationViewModel) -> String {
        if viewModel.finished { return "Assigned" }
        switch viewModel.step {
        case .describe: "Draft"
        case .previews, .save: "Not Saved"
        case .assign: "Saved"
        }
    }

    private func stepBack(_ viewModel: VoiceCreationViewModel) {
        if viewModel.finished {
            coordinator.pop()
            return
        }
        switch viewModel.step {
        case .describe: coordinator.pop()
        case .previews: viewModel.step = .describe
        case .save: viewModel.step = .previews
        case .assign: viewModel.step = .save
        }
    }

    // MARK: Step bar

    private func stepBar(_ current: VoiceCreationViewModel.Step) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(VoiceCreationViewModel.Step.allCases, id: \.rawValue) { step in
                    Capsule()
                        .fill(step.rawValue <= current.rawValue
                              ? Color.caInk : Color.caHairline)
                        .frame(height: 3)
                }
            }
            HStack(spacing: 4) {
                ForEach(VoiceCreationViewModel.Step.allCases, id: \.rawValue) { step in
                    Text("\(step.rawValue) \(step.label)")
                        .font(.caption2)
                        .foregroundStyle(step == current ? Color.caInk : Color.caSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: Step 1 — Describe

    private func describeContent(_ viewModel: VoiceCreationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("Create a voice")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    stepBar(.describe)
                    VoiceCapacityCard(capacity: viewModel.capacity)
                    if viewModel.capacity.availableSlots == 0 {
                        savingNeedsRoomNote
                    } else {
                        Text("Saving a new custom voice may use a voice slot "
                             + "in your ElevenLabs account.")
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                    }
                    fieldBlock("New voice name") {
                        TextField("Voice name", text: Binding(
                            get: { viewModel.draftName },
                            set: { viewModel.draftName = $0 }
                        ))
                        .textFieldStyle(.plain)
                    }
                    editorBlock("Voice description", text: Binding(
                        get: { viewModel.draftDescription },
                        set: { viewModel.draftDescription = $0 }
                    ))
                    editorBlock("Audition text", text: Binding(
                        get: { viewModel.draftAuditionText },
                        set: { viewModel.draftAuditionText = $0 }
                    ))
                    Text(viewModel.contextNote)
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    Text("1 Describe → 2 Generate / review previews → 3 Save "
                         + "to ElevenLabs → 4 Assign. Description approval is "
                         + "not a provider save or paid preview.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Generate previews") {
                viewModel.generatePreviews()
            }
            secondaryBar("Choose an existing voice") {
                coordinator.push(.savedVoices(projectID: projectID))
            }
        }
    }

    private var savingNeedsRoomNote: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 4) {
                Text("Saving needs room")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("Describing a voice and generating previews do not "
                     + "automatically consume or reserve a saved custom "
                     + "voice slot.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            .padding(Theme.Spacing.card)
        }
    }

    // MARK: Step 2 — Previews

    private func previewsContent(_ viewModel: VoiceCreationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("A voice you believe.")
                        .font(.caSerif(28))
                        .foregroundStyle(Color.caInk)
                    Text("Series narrator · Description approved · ElevenLabs")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    stepBar(.previews)
                    Button {
                        coordinator.push(.savedVoices(projectID: projectID))
                    } label: {
                        Text("Choose Saved Voice")
                    }
                    .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
                    VoiceCapacityCard(capacity: viewModel.capacity)
                    Text("Saving a new custom voice may use a voice slot "
                         + "in your ElevenLabs account.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                    ForEach(Array(viewModel.auditions.enumerated()), id: \.offset) { pair in
                        auditionCard(pair.element, index: pair.offset, viewModel)
                    }
                    requestAnotherCard(viewModel)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            miniPlayer(viewModel)
            BottomCTA(title: "Save Voice") {
                viewModel.step = .save
            }
        }
    }

    private func auditionCard(
        _ audition: VoiceAudition, index: Int, _ viewModel: VoiceCreationViewModel
    ) -> some View {
        let selected = viewModel.selectedAudition == index
        return CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button {
                        viewModel.selectAudition(index)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: selected
                                  ? "checkmark.square.fill" : "square")
                                .foregroundStyle(Color.caInk)
                            Text("Audition \(audition.label)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.caInk)
                        }
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    StatusBadge(selected ? "Selected · Ready" : "Ready",
                                kind: selected ? .warmLight : .neutral)
                    Text(ScriptReaderViewModel.format(audition.seconds))
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Text(audition.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.caSecondary)
                if index == 0 {
                    Text("Proposed name: \(viewModel.draftName) · Unsaved preview")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                Button {
                    viewModel.playAudition(index)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                        Text(selected ? "Play selected audition"
                                      : "Play audition \(audition.label.prefix(1))")
                    }
                    .font(.caption.weight(.medium))
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

    private func requestAnotherCard(_ viewModel: VoiceCreationViewModel) -> some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Request another audition")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.caInk)
                    Spacer()
                    StatusBadge("Paid · Est. unavailable", kind: .warm)
                }
                Text("Uses approved narrator description + selected passage "
                     + "via ElevenLabs. Your connected account may be "
                     + "charged. Cancel to keep existing auditions.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Text("Description approval does not trigger a charge. "
                     + "Preview-generation credits are separate from saving "
                     + "a custom voice. Save Voice checks current capacity "
                     + "and asks for confirmation; assignment follows "
                     + "provider-confirmed save.")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
                Button {
                    coordinator.push(.placeholder(title: "Paid audition", milestone: "M12"))
                } label: {
                    Text("Confirm paid audition")
                }
                .buttonStyle(CAPrimaryButtonStyle(fullWidth: true))
            }
            .padding(Theme.Spacing.card)
        }
    }

    private func miniPlayer(_ viewModel: VoiceCreationViewModel) -> some View {
        let audition = viewModel.auditions[viewModel.selectedAudition]
        return HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.caInk)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.draftName) Preview \(audition.label.prefix(1))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text("00:08 — \(ScriptReaderViewModel.format(audition.seconds)) · 1×")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.vertical, 8)
    }

    // MARK: Step 3 — Save

    private func saveContent(_ viewModel: VoiceCreationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("Review your previews")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text("\(viewModel.draftName) · Description approved")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    stepBar(.save)
                    ForEach(Array(viewModel.auditions.enumerated()), id: \.offset) { pair in
                        previewRow(pair.element, index: pair.offset, viewModel)
                    }
                    Text("Fresh provider check complete. Ready to save the "
                         + "selected preview; no assignment changes yet.")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    fieldBlock("New voice name") {
                        TextField("Voice name", text: Binding(
                            get: { viewModel.draftName },
                            set: { viewModel.draftName = $0 }
                        ))
                        .textFieldStyle(.plain)
                    }
                    previewRow(viewModel.auditions[viewModel.selectedAudition],
                               index: viewModel.selectedAudition, viewModel)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Voice description")
                            .font(.subheadline.weight(.medium))
                        Text(viewModel.draftDescription)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.caField)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Audition text")
                            .font(.subheadline.weight(.medium))
                        Text(viewModel.draftAuditionText)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.caField)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    Text("\(viewModel.contextNote) · Preview "
                         + "\(viewModel.auditions[viewModel.selectedAudition].label.prefix(1)) "
                         + "selected.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Save Voice") {
                viewModel.saveVoice()
            }
        }
    }

    private func previewRow(
        _ audition: VoiceAudition, index: Int, _ viewModel: VoiceCreationViewModel
    ) -> some View {
        let selected = viewModel.selectedAudition == index
        return HStack(spacing: 12) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.caInk)
            VStack(alignment: .leading, spacing: 4) {
                Text("Preview \(audition.label.capitalized)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.caInk)
                Text((selected ? "Selected · " : "")
                     + "00:00 — \(ScriptReaderViewModel.format(audition.seconds)) · 1×")
                    .font(.caption)
                    .foregroundStyle(Color.caSecondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.card)
        .background(selected ? Color.caPill : Color.caSurface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    // MARK: Step 4 — Assign

    private func assignContent(_ viewModel: VoiceCreationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("Assign \(viewModel.draftName)?")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text("Single-narrator project")
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    stepBar(.assign)
                    CardContainer {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Saved provider voice")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.caInk)
                            previewRow(
                                viewModel.auditions[viewModel.selectedAudition],
                                index: viewModel.selectedAudition, viewModel
                            )
                            Text("ElevenLabs save confirmed. Reusing this "
                                 + "voice consumes 0 additional slots.")
                                .font(.subheadline)
                                .foregroundStyle(Color.caSecondary)
                        }
                        .padding(Theme.Spacing.card)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Project → Role")
                            .font(.subheadline.weight(.medium))
                        Text(viewModel.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.caSecondary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.caField)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    CardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(viewModel.project?.narratorName ?? "Current voice") "
                                 + "→ \(viewModel.draftName)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.caInk)
                            Text("Only Confirm assignment replaces the "
                                 + "current voice for this role. Your "
                                 + "current default remains until then; "
                                 + "existing audio files are unchanged.")
                                .font(.caption)
                                .foregroundStyle(Color.caSecondary)
                        }
                        .padding(Theme.Spacing.card)
                    }
                    VoiceCapacityCard(capacity: viewModel.capacity)
                    Text("Character descriptions are performance guides for "
                         + "one narrator, not automatic separate generated "
                         + "character voices.")
                        .font(.caption)
                        .foregroundStyle(Color.caSecondary)
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Confirm assignment") {
                viewModel.confirmAssignment()
            }
            secondaryBar("Keep \(viewModel.project?.narratorName ?? "existing voice")") {
                viewModel.keepExisting()
            }
        }
    }

    // MARK: Success

    private func successContent(_ viewModel: VoiceCreationViewModel) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.cardGap) {
                    Text("\(viewModel.assignedName) is assigned")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.caInk)
                    Text(viewModel.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(Color.caSecondary)
                    stepBar(.assign)
                    CardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(
                                viewModel.reusedExisting
                                    ? "Existing voice reused" : "Voice assigned",
                                systemImage: "checkmark"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.caInk)
                            Text(viewModel.reusedExisting
                                 ? "\(viewModel.assignedName) is confirmed for "
                                   + "this role and remains the default "
                                   + "narrator. 0 additional custom voice "
                                   + "slots consumed."
                                 : "\(viewModel.assignedName) is confirmed "
                                   + "for this role. Existing audio files "
                                   + "are unaffected.")
                                .font(.subheadline)
                                .foregroundStyle(Color.caSecondary)
                        }
                        .padding(Theme.Spacing.card)
                    }
                    if viewModel.savedVoice != nil {
                        previewRow(
                            viewModel.auditions[viewModel.selectedAudition],
                            index: viewModel.selectedAudition, viewModel
                        )
                    }
                    VoiceCapacityCard(capacity: viewModel.capacity)
                    CardContainer {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Capacity is unchanged")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.caInk)
                            Text("Assignments, favorites and local saved "
                                 + "references do not create another "
                                 + "provider voice. Existing audio files "
                                 + "are unaffected.")
                                .font(.caption)
                                .foregroundStyle(Color.caSecondary)
                        }
                        .padding(Theme.Spacing.card)
                    }
                }
                .padding(.horizontal, Theme.Spacing.page)
                .padding(.vertical, Theme.Spacing.cardGap)
            }
            BottomCTA(title: "Back to casting") {
                coordinator.pop()
            }
            secondaryBar("Open existing audio") {
                if let projectID {
                    coordinator.push(.placeholder(title: "Chapter audio", milestone: "M8"))
                }
            }
        }
    }

    // MARK: Field helpers

    private func fieldBlock<Content: View>(
        _ label: String, @ViewBuilder _ content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.caField)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
    }

    private func editorBlock(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
            TextEditor(text: text)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color.caField)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.caHairline, lineWidth: 1)
                )
        }
    }

    private func secondaryBar(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(CASecondaryButtonStyle(fullWidth: true))
        .padding(.horizontal, Theme.Spacing.page)
        .padding(.bottom, 10)
        .background(Color.caSurface)
    }
}
